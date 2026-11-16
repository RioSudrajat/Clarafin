package ai

import (
	"strings"
	"unicode"
)

// CanonicalCategoryResult holds a normalized category strictly aligned with
// apps/mobile/lib/core/models/transaction_category_model.dart.
type CanonicalCategoryResult struct {
	CanonicalCategory     string `json:"canonical_category"`
	CanonicalMainCategory string `json:"canonical_main_category"`
	CanonicalSubcategory  string `json:"canonical_subcategory,omitempty"`
	Type                  string `json:"type"`
	IsFallback            bool   `json:"is_fallback,omitempty"`
}

type categoryDefinition struct {
	txType        string
	mainName      string
	subName       string
	canonicalName string
	isParent      bool
	aliases       []string
}

type compiledAliasRule struct {
	def         categoryDefinition
	aliasTokens []string
}

var (
	canonicalCatalog   = buildCanonicalCatalog()
	compiledAliasRules = compileAliasRules(canonicalCatalog)
)

// NormalizeCanonicalCategory maps raw category names, Indonesian colloquialisms,
// and merchant/title hints strictly onto verbatim TransactionCategories strings.
func NormalizeCanonicalCategory(rawCategory string, txType string, contextHint string) CanonicalCategoryResult {
	normType := normalizeTxType(txType)
	rawTrimmed := strings.TrimSpace(rawCategory)
	hintTrimmed := strings.TrimSpace(contextHint)

	if normType == "transfer" {
		if res, ok := matchIncomingTransfer(rawTrimmed); ok {
			return res
		}
		return CanonicalCategoryResult{
			CanonicalCategory:     "Transfer",
			CanonicalMainCategory: "Transfer",
			Type:                  "transfer",
		}
	}

	if isTransferPhrase(rawTrimmed) {
		return CanonicalCategoryResult{
			CanonicalCategory:     "Transfer",
			CanonicalMainCategory: "Transfer",
			Type:                  "transfer",
		}
	}

	// Step 1: Match explicit category input first, prioritizing requested txType.
	// Generic "Others" inputs under an explicit income type bypass expense "Others" matching
	// so they stay strictly within income inference and fallback.
	if rawTrimmed != "" && !(normType == "income" && isGenericOthersInput(rawTrimmed)) {
		if def, matched := resolveTextToCategory(rawTrimmed, normType, true); matched {
			if isGenericOthers(def) && hintTrimmed != "" {
				// "Others" / "General Uncategorized" paired with contextHint can upgrade into a specific category
				// within the requested type (never leaking across income/expense).
				if hintDef, ok := resolveTextToCategory(hintTrimmed, normType, false); ok {
					return resultFromDef(hintDef, false)
				}
			}
			if def.isParent {
				// Refine broad parent categories (e.g. "Makanan") using contextHint when a matching child exists.
				if hintTrimmed != "" && !isGenericOthers(def) {
					if childDef, ok := refineParentWithHint(def, hintTrimmed); ok {
						return resultFromDef(childDef, false)
					}
				}
			} else if def.canonicalName == "Transportation • Ride Hailing / Taxi" && isTransportasiOnly(rawTrimmed) && hintTrimmed != "" {
				// Keep "Transportasi" mapped to Ride Hailing / Taxi by default, while allowing
				// specific Transportation hints like "parkir" or "bensin" to narrow accurately.
				if childDef, ok := refineMainNameWithHint("Transportation", "expense", hintTrimmed); ok {
					return resultFromDef(childDef, false)
				}
			}
			return resultFromDef(def, false)
		}
	}

	// Step 2: Infer category from contextHint when rawCategory was empty or unknown.
	// Never cross-leak between income and expense when normType is explicitly constrained.
	if hintTrimmed != "" {
		if def, matched := resolveTextToCategory(hintTrimmed, normType, false); matched {
			return resultFromDef(def, false)
		}
	}

	// Step 3: Deterministic fallback strictly matching canonical categories.
	if normType == "income" {
		return CanonicalCategoryResult{
			CanonicalCategory:     "Income • Additional Income",
			CanonicalMainCategory: "Income",
			CanonicalSubcategory:  "Additional Income",
			Type:                  "income",
			IsFallback:            true,
		}
	}
	return CanonicalCategoryResult{
		CanonicalCategory:     "Others • General Uncategorized",
		CanonicalMainCategory: "Others",
		CanonicalSubcategory:  "General Uncategorized",
		Type:                  "expense",
		IsFallback:            true,
	}
}

func normalizeTxType(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "income":
		return "income"
	case "expense":
		return "expense"
	case "transfer":
		return "transfer"
	default:
		return ""
	}
}

func isGenericOthers(def categoryDefinition) bool {
	return def.mainName == "Others"
}

func isGenericOthersInput(raw string) bool {
	mainPart, subPart := splitCategoryParts(raw)
	if strings.EqualFold(mainPart, "Others") && (subPart == "" || strings.EqualFold(subPart, "General Uncategorized")) {
		return true
	}
	tokens := tokenizeForMatch(raw)
	if len(tokens) == 1 {
		switch tokens[0] {
		case "other", "others", "uncategorized", "lainnya", "umum":
			return true
		}
	}
	joined := strings.Join(tokens, " ")
	return joined == "general uncategorized" || joined == "lain lain"
}

func isTransportasiOnly(raw string) bool {
	tokens := tokenizeForMatch(raw)
	return len(tokens) == 1 && tokens[0] == "transportasi"
}

func isTransferPhrase(raw string) bool {
	tokens := tokenizeForMatch(raw)
	return len(tokens) == 1 && tokens[0] == "transfer"
}

func matchIncomingTransfer(raw string) (CanonicalCategoryResult, bool) {
	if raw == "" {
		return CanonicalCategoryResult{}, false
	}
	mainPart, subPart := splitCategoryParts(raw)
	if strings.EqualFold(mainPart, "Incoming Transfer") {
		if subPart == "" {
			return CanonicalCategoryResult{
				CanonicalCategory:     "Incoming Transfer",
				CanonicalMainCategory: "Incoming Transfer",
				Type:                  "transfer",
			}, true
		}
		for _, def := range canonicalCatalog {
			if def.mainName == "Incoming Transfer" && !def.isParent && strings.EqualFold(def.subName, subPart) {
				return CanonicalCategoryResult{
					CanonicalCategory:     def.canonicalName,
					CanonicalMainCategory: def.mainName,
					CanonicalSubcategory:  def.subName,
					Type:                  "transfer",
				}, true
			}
		}
	}
	return CanonicalCategoryResult{}, false
}

func refineParentWithHint(parent categoryDefinition, hint string) (categoryDefinition, bool) {
	return refineMainNameWithHint(parent.mainName, parent.txType, hint)
}

func refineMainNameWithHint(mainName, txType, hint string) (categoryDefinition, bool) {
	hintTokens := tokenizeForMatch(hint)
	if len(hintTokens) == 0 {
		return categoryDefinition{}, false
	}

	bestScore := 0
	var bestDef categoryDefinition
	matched := false

	for _, rule := range compiledAliasRules {
		if rule.def.isParent || rule.def.mainName != mainName || rule.def.txType != txType {
			continue
		}
		if matchTokenSequence(hintTokens, rule.aliasTokens) {
			score := len(rule.aliasTokens) * 10
			if !matched || score > bestScore {
				bestScore = score
				bestDef = rule.def
				matched = true
			}
		}
	}
	return bestDef, matched
}

func resolveTextToCategory(text string, preferredType string, allowCrossType bool) (categoryDefinition, bool) {
	if preferredType != "" {
		if def, ok := matchVerbatimCategory(text, preferredType); ok {
			return def, true
		}
		if def, ok := matchAliasRules(text, preferredType); ok {
			return def, true
		}
		if allowCrossType {
			otherType := "income"
			if preferredType == "income" {
				otherType = "expense"
			}
			if def, ok := matchVerbatimCategory(text, otherType); ok {
				return def, true
			}
			if def, ok := matchAliasRules(text, otherType); ok {
				return def, true
			}
		}
		return categoryDefinition{}, false
	}

	if def, ok := matchVerbatimCategory(text, ""); ok {
		return def, true
	}
	if def, ok := matchAliasRules(text, ""); ok {
		return def, true
	}
	return categoryDefinition{}, false
}

func matchVerbatimCategory(raw string, typeFilter string) (categoryDefinition, bool) {
	mainPart, subPart := splitCategoryParts(raw)
	if mainPart == "" {
		return categoryDefinition{}, false
	}

	// 1. Exact "Main • Sub" or "Main - Sub" match.
	if subPart != "" {
		for _, def := range canonicalCatalog {
			if typeFilter != "" && def.txType != typeFilter {
				continue
			}
			if !def.isParent && strings.EqualFold(def.mainName, mainPart) && strings.EqualFold(def.subName, subPart) {
				return def, true
			}
		}
	}

	// 2. Exact parent category name match (defaulting to expense when typeFilter is empty).
	var parentMatches []categoryDefinition
	for _, def := range canonicalCatalog {
		if typeFilter != "" && def.txType != typeFilter {
			continue
		}
		if def.isParent && strings.EqualFold(def.mainName, mainPart) && subPart == "" {
			parentMatches = append(parentMatches, def)
		}
	}
	if len(parentMatches) > 0 {
		for _, def := range parentMatches {
			if def.txType == "expense" {
				return def, true
			}
		}
		return parentMatches[0], true
	}

	// 3. Exact bare subcategory name match (e.g. "Coffee Shop", "Salary").
	if subPart == "" {
		for _, def := range canonicalCatalog {
			if typeFilter != "" && def.txType != typeFilter {
				continue
			}
			if !def.isParent && strings.EqualFold(def.subName, mainPart) {
				return def, true
			}
		}
	}

	return categoryDefinition{}, false
}

func matchAliasRules(text string, typeFilter string) (categoryDefinition, bool) {
	tokens := tokenizeForMatch(text)
	if len(tokens) == 0 {
		return categoryDefinition{}, false
	}

	bestScore := -1
	var bestDef categoryDefinition
	matched := false

	for _, rule := range compiledAliasRules {
		if typeFilter != "" && rule.def.txType != typeFilter {
			continue
		}
		if !matchTokenSequence(tokens, rule.aliasTokens) {
			continue
		}
		// Prefer longer multi-word alias phrases, then subcategories over broad parents,
		// and expense over income only when txType was left completely unspecified.
		score := len(rule.aliasTokens) * 100
		if !rule.def.isParent {
			score += 20
		}
		if typeFilter == "" && rule.def.txType == "expense" {
			score += 1
		}
		if !matched || score > bestScore {
			bestScore = score
			bestDef = rule.def
			matched = true
		}
	}

	return bestDef, matched
}

func resultFromDef(def categoryDefinition, isFallback bool) CanonicalCategoryResult {
	return CanonicalCategoryResult{
		CanonicalCategory:     def.canonicalName,
		CanonicalMainCategory: def.mainName,
		CanonicalSubcategory:  def.subName,
		Type:                  def.txType,
		IsFallback:            isFallback,
	}
}

func splitCategoryParts(raw string) (string, string) {
	clean := strings.TrimSpace(raw)
	if clean == "" {
		return "", ""
	}
	for _, sep := range []string{"•", " - ", ":"} {
		if idx := strings.Index(clean, sep); idx >= 0 {
			mainPart := strings.TrimSpace(clean[:idx])
			subPart := strings.TrimSpace(clean[idx+len(sep):])
			return mainPart, subPart
		}
	}
	return clean, ""
}

func tokenizeForMatch(s string) []string {
	lower := strings.ToLower(strings.TrimSpace(s))
	if lower == "" {
		return nil
	}
	return strings.FieldsFunc(lower, func(r rune) bool {
		return !unicode.IsLetter(r) && !unicode.IsDigit(r)
	})
}

func matchTokenSequence(haystack []string, needle []string) bool {
	if len(needle) == 0 || len(needle) > len(haystack) {
		return false
	}
	limit := len(haystack) - len(needle)
	for i := 0; i <= limit; i++ {
		ok := true
		for j := 0; j < len(needle); j++ {
			if haystack[i+j] != needle[j] {
				ok = false
				break
			}
		}
		if ok {
			return true
		}
	}
	return false
}

func compileAliasRules(defs []categoryDefinition) []compiledAliasRule {
	rules := make([]compiledAliasRule, 0, len(defs)*4)
	for _, def := range defs {
		for _, alias := range def.aliases {
			toks := tokenizeForMatch(alias)
			if len(toks) == 0 {
				continue
			}
			rules = append(rules, compiledAliasRule{
				def:         def,
				aliasTokens: toks,
			})
		}
	}
	return rules
}

func parentDef(txType, mainName string, aliases ...string) categoryDefinition {
	return categoryDefinition{
		txType:        txType,
		mainName:      mainName,
		canonicalName: mainName,
		isParent:      true,
		aliases:       aliases,
	}
}

func subDef(txType, mainName, subName string, aliases ...string) categoryDefinition {
	return categoryDefinition{
		txType:        txType,
		mainName:      mainName,
		subName:       subName,
		canonicalName: mainName + " • " + subName,
		isParent:      false,
		aliases:       aliases,
	}
}

func buildCanonicalCatalog() []categoryDefinition {
	return []categoryDefinition{
		// Income categories (6 parents + 15 subcategories)
		parentDef("income", "Income", "pemasukan", "pendapatan", "penghasilan"),
		subDef("income", "Income", "Salary", "gaji", "gajian", "salary", "payroll", "upah", "thr", "tunjangan", "honor", "gaji bulanan"),
		subDef("income", "Income", "Bonus", "bonus", "insentif", "incentive", "komisi", "commission"),
		subDef("income", "Income", "Pocket Money", "uang saku", "uang jajan", "pocket money", "kiriman orang tua"),
		subDef("income", "Income", "Additional Income", "penghasilan tambahan", "additional income", "other income", "side income", "extra income", "income others", "income • others", "pemasukan lain", "side hustle", "sampingan"),

		parentDef("income", "Business", "pemasukan bisnis", "omset usaha", "pendapatan bisnis"),
		subDef("income", "Business", "Sales Revenue", "penjualan", "omzet", "omset", "jualan", "sales", "sales revenue", "hasil jualan", "pendapatan toko"),
		subDef("income", "Business", "Freelance & Client", "freelance", "klien", "client", "fee proyek", "honor proyek"),

		parentDef("income", "Investment", "hasil investasi", "return investasi"),
		subDef("income", "Investment", "Dividends", "dividen", "dividend", "dividends", "bagi hasil"),
		subDef("income", "Investment", "Capital Gains", "capital gain", "capital gains", "profit saham", "cuan", "profit investasi"),
		subDef("income", "Investment", "Bank Interest", "bunga bank", "bank interest", "bunga deposito", "bunga tabungan", "kupon sbn", "kupon obligasi"),

		parentDef("income", "Gift", "hadiah", "kado", "hadiah masuk", "pemberian"),
		subDef("income", "Gift", "From Family", "hadiah keluarga", "from family", "angpao", "thr keluarga"),
		subDef("income", "Gift", "Rewards / Cashback", "cashback", "reward", "rewards", "promo cashback"),

		parentDef("income", "Loans", "pencairan pinjaman"),
		subDef("income", "Loans", "Bank Loan", "pinjaman bank", "bank loan", "pencairan kredit"),
		subDef("income", "Loans", "Personal Borrowing", "personal borrowing", "pinjam uang"),

		parentDef("income", "Incoming Transfer", "incoming transfer", "transfer masuk"),
		subDef("income", "Incoming Transfer", "Inter-Bank Transfer", "inter-bank transfer", "terima transfer"),
		subDef("income", "Incoming Transfer", "E-Wallet Top-up", "e-wallet top-up", "topup masuk", "top up masuk"),

		// Expense categories: DAILY NEEDS
		parentDef("expense", "Food & Beverage", "makanan", "makan", "minuman", "minum", "fnb", "f b", "food", "beverage", "kuliner", "jajan", "snack", "cemilan", "air mineral", "air putih"),
		subDef("expense", "Food & Beverage", "Restaurant", "warteg", "street food", "hawker", "street food & hawker", "restoran", "resto", "restaurant", "rumah makan", "nasi padang", "padang", "warung", "bakso", "mie ayam", "gacoan", "sate", "soto", "ayam geprek", "geprek", "sushi", "ramen", "solaria", "makan siang", "makan malam", "sarapan", "lunch", "dinner", "breakfast"),
		subDef("expense", "Food & Beverage", "Food delivery", "gofood", "go food", "grabfood", "grab food", "shopeefood", "shopee food", "food delivery", "pesan makan"),
		subDef("expense", "Food & Beverage", "Coffee Shop", "kopi", "coffee", "coffee shop", "kopi kenangan", "kenangan", "starbucks", "sbux", "fore", "fore coffee", "janji jiwa", "janjijiwa", "kopi tuku", "tuku", "point coffee", "tomoro", "kulo", "flash coffee", "chatime", "mixue", "boba", "cafe", "kafe", "ngopi", "warkop", "espresso", "latte"),
		subDef("expense", "Food & Beverage", "Fast Food", "fast food", "fastfood", "mcd", "mcdonalds", "kfc", "burger king", "hokben", "richeese", "pizza hut", "dominos", "burger", "fried chicken"),
		subDef("expense", "Food & Beverage", "Alcoholic Beverages", "alcoholic beverages", "alkohol", "alcohol", "bir", "beer", "bir bintang", "wine", "soju", "cocktail", "whisky"),
		subDef("expense", "Food & Beverage", "Bakery & Cake Shop", "bakery", "cake", "bakery & cake shop", "roti", "kue", "breadtalk", "mako", "holland bakery", "jco", "dunkin", "donat", "donut", "croissant", "martabak"),

		parentDef("expense", "Transportation", "transportation", "transport", "ongkos"),
		subDef("expense", "Transportation", "Public Transport", "public transport", "krl", "commuter", "commuter line", "mrt", "lrt", "transjakarta", "busway", "bus", "angkot", "kereta", "kai", "whoosh"),
		subDef("expense", "Transportation", "Ride Hailing / Taxi", "transportasi", "ojol", "ojek", "gojek", "goride", "gocar", "grab", "grabbike", "grabcar", "maxim", "indrive", "bluebird", "taksi", "taxi", "ride hailing"),
		subDef("expense", "Transportation", "Fuel & Gas", "bensin", "bbm", "pertamax", "pertalite", "solar", "dexlite", "spbu", "pom bensin", "isi bensin", "fuel", "fuel & gas", "fuel / gas"),
		subDef("expense", "Transportation", "Parking & Toll", "parkir", "parking", "e-toll", "etoll", "toll", "tol", "karcis parkir", "valet"),
		subDef("expense", "Transportation", "Vehicle Maintenance", "vehicle maintenance", "servis motor", "service motor", "servis mobil", "service mobil", "ganti oli", "oli", "bengkel", "cuci mobil", "cuci motor", "tambal ban", "sparepart"),

		// Expense categories: HOUSEHOLD NEEDS
		parentDef("expense", "Household Needs", "household", "household needs", "kebutuhan rumah", "rumah tangga"),
		subDef("expense", "Household Needs", "Groceries / Belanja Dapur", "groceries", "belanja dapur", "belanja bulanan", "supermarket", "minimarket", "indomaret", "alfamart", "alfamidi", "superindo", "hypermart", "transmart", "sembako", "beras", "sayur", "minyak goreng", "gas lpg", "elpiji", "galon air"),
		subDef("expense", "Household Needs", "Cleaning Supplies", "cleaning supplies", "sabun cuci", "detergen", "deterjen", "pewangi", "pembersih", "tisu", "tissue"),
		subDef("expense", "Household Needs", "Home Repair", "home repair", "perbaikan rumah", "renovasi", "tukang", "cat rumah"),
		subDef("expense", "Household Needs", "Rent / Sewa", "rent", "sewa", "sewa rumah", "sewa apartemen", "kos", "kost", "kontrakan", "ipl", "apartemen"),

		parentDef("expense", "Bills & Utilities", "tagihan", "bill", "bills", "utilities", "bills & utilities"),
		subDef("expense", "Bills & Utilities", "Electricity / Listrik PLN", "listrik", "pln", "token listrik", "token pln", "tagihan listrik", "electricity"),
		subDef("expense", "Bills & Utilities", "Water / Air PDAM", "pdam", "air pdam", "tagihan air", "bayar air", "air bersih", "water"),
		subDef("expense", "Bills & Utilities", "Internet & Wi-Fi", "internet", "wifi", "wi fi", "indihome", "biznet", "myrepublic", "firstmedia", "first media"),
		subDef("expense", "Bills & Utilities", "Phone & Mobile Data", "pulsa", "kuota", "paket data", "telkomsel", "indosat", "xl", "axis", "smartfren", "byu", "mobile data"),
		subDef("expense", "Bills & Utilities", "Digital Subscriptions", "netflix", "spotify", "youtube premium", "disney", "icloud", "google one", "chatgpt", "claude", "canva", "subscription", "subscriptions", "langganan"),

		parentDef("expense", "Pets", "pets", "pet", "hewan peliharaan", "anabul"),
		subDef("expense", "Pets", "Pet Food", "pet food", "makanan kucing", "makanan anjing", "whiskas", "royal canin", "pasir kucing"),
		subDef("expense", "Pets", "Veterinary / Dokter", "dokter hewan", "veterinary", "vaksin kucing", "vaksin anjing"),
		subDef("expense", "Pets", "Grooming & Toys", "grooming", "pet shop", "petshop", "mainan kucing", "mainan anjing"),

		parentDef("expense", "Family", "family", "keluarga"),
		subDef("expense", "Family", "Childcare & Needs", "childcare", "popok", "diapers", "pampers", "susu anak", "susu bayi", "daycare", "kebutuhan anak"),
		subDef("expense", "Family", "Allowance to Parents", "orang tua", "ortu", "kiriman ortu", "uang bulanan ortu", "allowance to parents"),
		subDef("expense", "Family", "Family Events", "family events", "acara keluarga", "arisan", "reuni"),

		// Expense categories: PERSONAL NEEDS
		parentDef("expense", "Shopping", "belanja", "shopping", "tokopedia", "shopee", "lazada", "blibli", "tiktok shop"),
		subDef("expense", "Shopping", "Clothing & Fashion", "baju", "celana", "kaos", "kemeja", "jaket", "hoodie", "dress", "uniqlo", "zara", "pakaian", "fashion", "clothing"),
		subDef("expense", "Shopping", "Electronics & Gadgets", "elektronik", "gadget", "gadgets", "smartphone", "iphone", "samsung", "laptop", "macbook", "ipad", "headphone", "tws", "earphone", "charger", "keyboard", "mouse", "erafone", "ibox", "electronics"),
		subDef("expense", "Shopping", "Beauty & Skincare", "skincare", "makeup", "kosmetik", "beauty", "sociolla", "serum", "sunscreen", "lipstik", "parfum"),
		subDef("expense", "Shopping", "Shoes & Accessories", "sepatu", "tas", "jam tangan", "kacamata", "shoes", "accessories", "sneakers", "nike", "adidas"),

		parentDef("expense", "Health & Sports", "kesehatan", "health", "olahraga", "sports", "health & sports", "medis"),
		subDef("expense", "Health & Sports", "Doctor & Hospital", "dokter", "rumah sakit", "klinik", "puskesmas", "halodoc", "alodokter", "konsultasi dokter", "dokter gigi", "dental", "hospital", "doctor", "bpjs kesehatan"),
		subDef("expense", "Health & Sports", "Medicine & Pharmacy", "obat", "apotek", "apotik", "kimia farma", "century", "k24", "guardian", "watsons", "vitamin", "suplemen", "medicine", "pharmacy"),
		subDef("expense", "Health & Sports", "Gym & Fitness Membership", "gym", "fitness", "pilates", "yoga", "fithub", "celebrity fitness", "fitness first", "padel", "badminton", "futsal", "renang"),
		subDef("expense", "Health & Sports", "Sports Equipment", "alat olahraga", "sports equipment", "raket", "barbel", "matras yoga"),

		parentDef("expense", "Donations & Gifts", "donations", "donations & gifts", "sumbangan"),
		subDef("expense", "Donations & Gifts", "Charity & Infaq", "sedekah", "infaq", "infak", "donasi", "charity", "amal", "kitabisa", "baznas"),
		subDef("expense", "Donations & Gifts", "Gifts & Presents", "kado", "hadiah", "kondangan", "bingkisan", "hampers", "gifts", "presents"),
		subDef("expense", "Donations & Gifts", "Zakat", "zakat", "zakat fitrah", "zakat mal", "zakat penghasilan"),

		parentDef("expense", "Travel", "travel", "liburan", "vacation", "trip", "mudik"),
		subDef("expense", "Travel", "Flight & Train Tickets", "tiket pesawat", "pesawat", "garuda", "citilink", "lion air", "airasia", "batik air", "tiket kereta", "kereta api", "traveloka", "tiket com", "flight", "airport", "bandara"),
		subDef("expense", "Travel", "Hotel & Lodging", "hotel", "staycation", "penginapan", "villa", "resort", "airbnb", "reddoorz", "oyo", "lodging"),
		subDef("expense", "Travel", "Attractions & Tours", "wisata", "tiket masuk", "tour", "dufan", "taman safari", "museum", "attractions"),

		parentDef("expense", "Entertainment", "hiburan", "entertainment", "karaoke", "rekreasi"),
		subDef("expense", "Entertainment", "Cinema & Movies", "bioskop", "nonton", "xxi", "cinema", "cgv", "cinepolis", "film", "movie", "movies", "tiket bioskop"),
		subDef("expense", "Entertainment", "Games & Top-up", "game", "games", "topup game", "top up game", "steam", "playstation", "ps5", "nintendo", "mlbb", "mobile legends", "valorant", "genshin", "robux", "voucher game"),
		subDef("expense", "Entertainment", "Concerts & Events", "konser", "concert", "concerts", "tiket konser", "festival", "pameran"),
		subDef("expense", "Entertainment", "Hobbies & Crafts", "hobi", "hobby", "hobbies", "komik", "manga", "lego", "gundam", "crafts"),

		parentDef("expense", "Education", "pendidikan", "education", "kuliah", "sekolah"),
		subDef("expense", "Education", "Courses & Certification", "kursus", "course", "courses", "bootcamp", "udemy", "coursera", "sertifikasi", "bimbel", "ruangguru", "webinar", "seminar", "pelatihan"),
		subDef("expense", "Education", "Books & Stationery", "buku", "gramedia", "alat tulis", "atk", "stationery", "books", "novel"),
		subDef("expense", "Education", "Tuition / SPP", "spp", "ukt", "uang kuliah", "uang sekolah", "tuition", "uang gedung"),

		// Expense categories: FINANCE
		parentDef("expense", "Loans", "utang", "hutang", "pinjaman", "loans", "loan"),
		subDef("expense", "Loans", "Mortgage / KPR", "kpr", "cicilan rumah", "angsuran rumah", "mortgage"),
		subDef("expense", "Loans", "Vehicle Installment", "cicilan motor", "cicilan mobil", "leasing", "adira", "fif", "angsuran kendaraan", "vehicle installment"),
		subDef("expense", "Loans", "Personal Loan", "cicilan", "angsuran", "paylater", "kredivo", "akulaku", "spaylater", "gopaylater", "pinjol", "kta", "personal loan"),
		subDef("expense", "Loans", "Credit Card Bill", "kartu kredit", "tagihan kartu kredit", "credit card"),

		parentDef("expense", "Investment", "investasi", "investment"),
		subDef("expense", "Investment", "Stocks / Saham", "saham", "stocks", "stockbit", "ajaib", "bbca", "ipot", "beli saham"),
		subDef("expense", "Investment", "Mutual Funds / Reksadana", "reksadana", "reksa dana", "mutual fund", "mutual funds", "bibit", "bareksa"),
		subDef("expense", "Investment", "Crypto Assets", "crypto", "kripto", "bitcoin", "btc", "eth", "solana", "usdt", "pintu", "indodax", "tokocrypto", "binance"),
		subDef("expense", "Investment", "Gold / Emas", "emas", "gold", "antam", "logam mulia", "pegadaian emas"),

		parentDef("expense", "Business", "bisnis", "usaha", "modal usaha", "business"),
		subDef("expense", "Business", "Operations & Utilities", "operasional bisnis", "operasional toko", "sewa kantor", "gaji karyawan", "operations"),
		subDef("expense", "Business", "Inventory & Supplies", "stok barang", "kulakan", "supplier", "inventory", "bahan baku"),
		subDef("expense", "Business", "Marketing & Ads", "iklan", "ads", "meta ads", "facebook ads", "google ads", "tiktok ads", "endorse", "marketing"),

		parentDef("expense", "Other Financial Expenses", "biaya keuangan", "other financial expenses", "keuangan lain"),
		subDef("expense", "Other Financial Expenses", "Bank Admin Fees", "biaya admin", "admin bank", "biaya transfer", "biaya bulanan bank", "bank admin", "admin fee", "materai"),
		subDef("expense", "Other Financial Expenses", "Taxes / Pajak", "pajak", "tax", "taxes", "pph", "ppn", "pbb", "pajak kendaraan", "stnk", "samsat"),
		subDef("expense", "Other Financial Expenses", "Insurance Premium", "asuransi", "premi asuransi", "insurance", "allianz", "prudential", "aia", "manulife", "bpjs ketenagakerjaan"),

		// Expense categories: SERVICES
		parentDef("expense", "Other Services", "jasa", "layanan", "other services", "services"),
		subDef("expense", "Other Services", "Laundry", "laundry", "londri", "cuci baju", "cuci sepatu", "dry clean"),
		subDef("expense", "Other Services", "Salon & Barbershop", "salon", "barbershop", "potong rambut", "cukur", "pangkas rambut", "creambath", "manicure"),
		subDef("expense", "Other Services", "Repair & Tech Services", "service hp", "servis hp", "service laptop", "servis laptop", "service ac", "cuci ac", "tukang kunci", "reparasi", "repair"),
		subDef("expense", "Other Services", "Courier & Postage", "jne", "jnt", "j t", "sicepat", "anteraja", "pos indonesia", "gosend", "grabexpress", "paxel", "lalamove", "ongkir", "kurir", "courier", "postage"),

		// Expense categories: OTHERS
		parentDef("expense", "Others"),
		subDef("expense", "Others", "General Uncategorized", "general uncategorized", "uncategorized", "lainnya", "lain lain", "umum"),
	}
}
