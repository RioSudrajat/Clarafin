package prompts

import (
	"bytes"
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"fmt"
	"strings"
	"text/template"
)

//go:embed clarafin_ai_system_v2.tmpl
var systemPromptV2Template string

var parsedSystemPromptV2 = template.Must(template.New("clarafin_ai_system_v2").Parse(systemPromptV2Template))

// FewShotExample pairs realistic Indonesian user slang/edge cases with expected tool calls and JSON output.
type FewShotExample struct {
	Name              string `json:"name"`
	UserPrompt        string `json:"user_prompt"`
	ExpectedTools     string `json:"expected_tools"`
	IdealResponseJSON string `json:"ideal_response_json"`
}

// SystemPromptInput configures dynamic runtime variables rendered into clarafin_ai_system_v2.tmpl.
type SystemPromptInput struct {
	SurfaceMode    string
	CurrentDateWIB string
}

// RenderSystemPromptV2 renders the immutable System Prompt v2 prefix (Modules A-E, categories, catalog, few-shots).
func RenderSystemPromptV2(in SystemPromptInput) (string, error) {
	surface := strings.TrimSpace(in.SurfaceMode)
	if surface != "quick_sheet" && surface != "full_screen" {
		surface = "full_screen"
	}
	dateWIB := strings.TrimSpace(in.CurrentDateWIB)
	if dateWIB == "" {
		dateWIB = "2026-11-17 (WIB)"
	}

	var buf bytes.Buffer
	err := parsedSystemPromptV2.Execute(&buf, map[string]string{
		"SurfaceMode":             surface,
		"CurrentDateWIB":          dateWIB,
		"CanonicalCategoriesText": CanonicalCategoriesPromptBlock(),
		"CatalogSummaryText":      CanonicalCatalogPromptBlock(),
		"FewShotText":             FormatFewShotPromptBlock(DefaultFewShotExamples()),
	})
	if err != nil {
		return "", fmt.Errorf("execute system prompt v2 template: %w", err)
	}
	return buf.String(), nil
}

// PrefixHash computes a deterministic SHA-256 cache key suffix for immutable prompt prefixes.
func PrefixHash(parts ...string) string {
	h := sha256.New()
	for _, p := range parts {
		_, _ = h.Write([]byte(p))
		_, _ = h.Write([]byte{0})
	}
	return hex.EncodeToString(h.Sum(nil))[:24]
}

// CanonicalCategoriesPromptBlock lists all 24 parent categories, 81 subcategories, and Transfer verbatim.
func CanonicalCategoriesPromptBlock() string {
	return strings.TrimSpace(`
INCOME CATEGORIES:
- Income: Income • Salary | Income • Bonus | Income • Pocket Money | Income • Additional Income
- Business: Business • Sales Revenue | Business • Freelance & Client
- Investment: Investment • Dividends | Investment • Capital Gains | Investment • Bank Interest
- Gift: Gift • From Family | Gift • Rewards / Cashback
- Loans: Loans • Bank Loan | Loans • Personal Borrowing
- Incoming Transfer: Incoming Transfer • Inter-Bank Transfer | Incoming Transfer • E-Wallet Top-up

EXPENSE CATEGORIES (DAILY NEEDS):
- Food & Beverage: Food & Beverage • Restaurant | Food & Beverage • Food delivery | Food & Beverage • Coffee Shop | Food & Beverage • Fast Food | Food & Beverage • Alcoholic Beverages | Food & Beverage • Bakery & Cake Shop
- Transportation: Transportation • Public Transport | Transportation • Ride Hailing / Taxi | Transportation • Fuel & Gas | Transportation • Parking & Toll | Transportation • Vehicle Maintenance

EXPENSE CATEGORIES (HOUSEHOLD NEEDS):
- Household Needs: Household Needs • Groceries / Belanja Dapur | Household Needs • Cleaning Supplies | Household Needs • Home Repair | Household Needs • Rent / Sewa
- Bills & Utilities: Bills & Utilities • Electricity / Listrik PLN | Bills & Utilities • Water / Air PDAM | Bills & Utilities • Internet & Wi-Fi | Bills & Utilities • Phone & Mobile Data | Bills & Utilities • Digital Subscriptions
- Pets: Pets • Pet Food | Pets • Veterinary / Dokter | Pets • Grooming & Toys
- Family: Family • Childcare & Needs | Family • Allowance to Parents | Family • Family Events

EXPENSE CATEGORIES (PERSONAL NEEDS):
- Shopping: Shopping • Clothing & Fashion | Shopping • Electronics & Gadgets | Shopping • Beauty & Skincare | Shopping • Shoes & Accessories
- Health & Sports: Health & Sports • Doctor & Hospital | Health & Sports • Medicine & Pharmacy | Health & Sports • Gym & Fitness Membership | Health & Sports • Sports Equipment
- Donations & Gifts: Donations & Gifts • Charity & Infaq | Donations & Gifts • Gifts & Presents | Donations & Gifts • Zakat
- Travel: Travel • Flight & Train Tickets | Travel • Hotel & Lodging | Travel • Attractions & Tours
- Entertainment: Entertainment • Cinema & Movies | Entertainment • Games & Top-up | Entertainment • Concerts & Events | Entertainment • Hobbies & Crafts
- Education: Education • Courses & Certification | Education • Books & Stationery | Education • Tuition / SPP

EXPENSE CATEGORIES (FINANCE, SERVICES, OTHERS):
- Loans: Loans • Mortgage / KPR | Loans • Vehicle Installment | Loans • Personal Loan | Loans • Credit Card Bill
- Investment: Investment • Stocks / Saham | Investment • Mutual Funds / Reksadana | Investment • Crypto Assets | Investment • Gold / Emas
- Business: Business • Operations & Utilities | Business • Inventory & Supplies | Business • Marketing & Ads
- Other Financial Expenses: Other Financial Expenses • Bank Admin Fees | Other Financial Expenses • Taxes / Pajak | Other Financial Expenses • Insurance Premium
- Other Services: Other Services • Laundry | Other Services • Salon & Barbershop | Other Services • Repair & Tech Services | Other Services • Courier & Postage
- Others: Others • General Uncategorized

TRANSFER:
- Transfer (untuk pindah dana antar dompet milik pengguna)
Catatan BudgetDraft: field category pada BudgetDraft wajib menggunakan nama parent kategori pengeluaran (misal "Food & Beverage", "Transportation", "Shopping", "Bills & Utilities", "Entertainment").`)
}

// CanonicalCatalogPromptBlock summarizes the 15 official Clarafin packages and 6 verified practitioners.
func CanonicalCatalogPromptBlock() string {
	return strings.TrimSpace(`
15 PAKET RESMI CLARAFIN:
1. personal_basic (Personal Advisory • Basic): "Fondasi Arus Kas & Utang" | Online Rp 199.000 | Offline Rp 349.000
2. personal_medium (Personal Advisory • Medium): "Optimalisasi Aset & Proteksi" | Online Rp 299.000 | Offline Rp 449.000
3. personal_premium (Personal Advisory • Premium): "Menuju Kebebasan Finansial" | Online Rp 399.000 | Offline Rp 599.000
4. couple_pre_marriage (Couple Advisory • Pre-Marriage): "Siap Menikah Tanpa Drama Finansial" | Online Rp 349.000 | Offline Rp 529.000
5. couple_marriage (Couple Advisory • Marriage): "Satu Visi Bangun Aset Keluarga" | Online Rp 399.000 | Offline Rp 599.000
6. couple_premium (Couple Advisory • Premium): "Mapan Finansial Lintas Generasi" | Online Rp 549.000 | Offline Rp 799.000
7. umkm_basic (UMKM Advisory • Basic): "Omzet Ramai, Untung Nyata di Rekening" | Online Rp 349.000 | Offline Rp 549.000
8. umkm_medium (UMKM Advisory • Medium): "Ekspansi Cabang & Aman Pajak Bisnis" | Online Rp 549.000 | Offline Rp 799.000
9. umkm_premium (UMKM Advisory • Premium): "Perpanjang Runway & Siap Pendanaan Investor" | Online Rp 849.000 | Offline Rp 1.199.000
10. corporate_basic (Corporate Wellness • Basic): "Karyawan Produktif Bebas Jerat Pinjol" | Online Rp 2.500.000 | Offline Rp 4.500.000
11. corporate_medium (Corporate Wellness • Medium): "Klinik Finansial Privat & Retensi Talenta" | Online Rp 1.490.000 | Offline Rp 2.250.000
12. corporate_premium (Corporate Advisory • Premium): "Optimalisasi Kas Korporasi & Pajak Eksekutif" | Online Rp 1.490.000 | Offline Rp 2.190.000
13. checkup_basic (Financial Check-Up • Basic): "Bongkar Bocor Halus & Skor Keuanganmu" | Online Rp 149.000 | Offline Rp 279.000
14. checkup_medium (Financial Check-Up • Medium): "Bedah Tuntas Portofolio & Polis Asuransi" | Online Rp 279.000 | Offline Rp 429.000
15. checkup_premium (Financial Check-Up • Premium): "Peta Jalan Kekayaan & Pensiun Dini (360°)" | Online Rp 499.000 | Offline Rp 699.000

6 KONSULTAN KANONIS CLARAFIN:
- c1: Chrysan Gomargana, S.E., CFP® (Tier Medium, Jakarta Selatan, Individu Medium, Couple Pre-Marriage & Marriage, Check-Up Medium)
- c2: Nurhuzaifah Amini, M.M., CFP®, BKP (Tier Premium, Tangerang Selatan, Restrukturisasi Utang, Pajak & Bisnis UMKM, Individu Premium, KPR, Check-Up Premium)
- c3: Rian Pratama, S.Ak., QWP®, AWP® (Tier Basic, Surabaya, Individu Basic, UMKM Basic, Check-Up Basic)
- c4: Dr. Hendra Wijaya, MBA, CFA®, CFP® (Tier Premium, Jakarta Pusat, FIRE, Startup Runway, Saham & Portofolio, Corporate Premium)
- c5: Nadia Kusuma, S.Psi., CFP®, AEPP® (Tier Premium, Bandung, Couple Pre-Marriage/Marriage/Premium, Generasi Sandwich, Waris & Pendidikan Anak)
- c6: Budi Santoso, S.E., Ak., CPA, CFP® (Tier Medium, Yogyakarta, UMKM Basic & Medium, Pajak Bisnis, Corporate Basic & Medium, Individu Medium)`)
}

// DefaultFewShotExamples returns 14 Indonesian slang and edge-case golden examples for in-context learning.
func DefaultFewShotExamples() []FewShotExample {
	return []FewShotExample{
		{
			Name:          "multi_item_slang_k_goceng",
			UserPrompt:    "kopi kenangan 25k + parkir goceng pake gopay",
			ExpectedTools: `check_and_prepare_transaction(default_wallet_hint="gopay", items=[{title:"Kopi Kenangan", amount_idr:25000, type:"expense", raw_category:"kopi"}, {title:"Parkir", amount_idr:5000, type:"expense", raw_category:"parkir"}])`,
			IdealResponseJSON: `{
  "narrative": "Siap, aku buatkan draf pengeluaran via GoPay untuk Kopi Kenangan Rp 25.000 dan Parkir Rp 5.000 (total Rp 30.000). Silakan periksa lalu tekan Konfirmasi & Catat.",
  "thinking_summary": [
    {"step_number": 1, "title": "Mengenali item transaksi", "detail": "2 item pengeluaran terdeteksi: Rp 25.000 dan Rp 5.000 via GoPay", "status": "completed"},
    {"step_number": 2, "title": "Memvalidasi dompet & kategori", "detail": "Dompet GoPay aktif dan kategori dipetakan ke Coffee Shop serta Parking & Toll", "status": "completed"}
  ],
  "transaction_draft": {
    "item_count": 2,
    "total_amount_idr": 30000,
    "items": [
      {"title": "Kopi Kenangan", "amount_idr": 25000, "type": "expense", "canonical_category": "Food & Beverage • Coffee Shop", "canonical_main_category": "Food & Beverage", "wallet_name": "GoPay"},
      {"title": "Parkir", "amount_idr": 5000, "type": "expense", "canonical_category": "Transportation • Parking & Toll", "canonical_main_category": "Transportation", "wallet_name": "GoPay"}
    ]
  }
}`,
		},
		{
			Name:          "income_slang_jt_bca",
			UserPrompt:    "baru dpt transferan gaji 8,5jt masuk bca",
			ExpectedTools: `check_and_prepare_transaction(items=[{title:"Gaji Bulanan", amount_idr:8500000, type:"income", raw_category:"gaji", wallet_hint:"bca"}])`,
			IdealResponseJSON: `{
  "narrative": "Draf pemasukan gaji sebesar Rp 8.500.000 ke dompet BCA sudah siap. Cek detailnya di bawah sebelum kamu simpan.",
  "thinking_summary": [
    {"step_number": 1, "title": "Memeriksa dompet BCA", "detail": "Dompet BCA ditemukan pada daftar dompet aktif", "status": "completed"}
  ],
  "transaction_draft": {
    "item_count": 1,
    "total_amount_idr": 8500000,
    "items": [
      {"title": "Gaji Bulanan", "amount_idr": 8500000, "type": "income", "canonical_category": "Income • Salary", "canonical_main_category": "Income", "wallet_name": "BCA"}
    ]
  }
}`,
		},
		{
			Name:          "slang_gocap_cepek_seceng",
			UserPrompt:    "makan siang gocap sama parkir dua ribu pake ovo",
			ExpectedTools: `check_and_prepare_transaction(default_wallet_hint="ovo", items=[{title:"Makan Siang", amount_idr:50000, type:"expense", raw_category:"makan siang"}, {title:"Parkir", amount_idr:2000, type:"expense", raw_category:"parkir"}])`,
			IdealResponseJSON: `{
  "narrative": "Sudah aku siapkan draf pengeluaran OVO sebesar Rp 50.000 untuk Makan Siang dan Rp 2.000 untuk Parkir (total Rp 52.000).",
  "thinking_summary": [
    {"step_number": 1, "title": "Mengonversi slang nominal", "detail": "Gocap dihitung sebagai Rp 50.000 dan parkir Rp 2.000 pada dompet OVO", "status": "completed"}
  ],
  "transaction_draft": {
    "item_count": 2,
    "total_amount_idr": 52000,
    "items": [
      {"title": "Makan Siang", "amount_idr": 50000, "type": "expense", "canonical_category": "Food & Beverage • Restaurant", "canonical_main_category": "Food & Beverage", "wallet_name": "OVO"},
      {"title": "Parkir", "amount_idr": 2000, "type": "expense", "canonical_category": "Transportation • Parking & Toll", "canonical_main_category": "Transportation", "wallet_name": "OVO"}
    ]
  }
}`,
		},
		{
			Name:          "missing_wallet_prerequisite_bank_jago",
			UserPrompt:    "abis makan 45rb pake bank jago",
			ExpectedTools: `check_and_prepare_transaction(items=[{title:"Makan", amount_idr:45000, type:"expense", raw_category:"makan", wallet_hint:"bank jago"}]) -> status=missing_wallet`,
			IdealResponseJSON: `{
  "narrative": "Aku cek kamu belum punya dompet Bank Jago, saat ini yang terdaftar baru BCA dan GoPay. Buat dompet Bank Jago dulu di bawah ya biar saldo rapi, atau pilih dompetmu yang sudah ada kalau tadi salah sebut.",
  "thinking_summary": [
    {"step_number": 1, "title": "Memeriksa daftar dompet aktif", "detail": "Bank Jago belum terdaftar pada akun pengguna; draf transaksi ditahan sementara", "status": "completed"}
  ],
  "wallet_creation_draft": {
    "institution_id": "jago",
    "institution_name": "Bank Jago",
    "institution_type": "bank",
    "missing_wallet_hint": "bank jago",
    "existing_wallets": [
      {"name": "BCA", "type": "bank", "balance_idr": 5000000},
      {"name": "GoPay", "type": "ewallet", "balance_idr": 250000}
    ]
  }
}`,
		},
		{
			Name:          "transfer_between_wallets",
			UserPrompt:    "topup gopay 500rb dari bca",
			ExpectedTools: `check_and_prepare_transaction(items=[{title:"Top-up GoPay dari BCA", amount_idr:500000, type:"transfer", raw_category:"transfer", wallet_hint:"bca", target_wallet_hint:"gopay"}])`,
			IdealResponseJSON: `{
  "narrative": "Draf transfer Rp 500.000 dari BCA ke GoPay sudah siap. Tekan konfirmasi jika nominal dan dompet tujuan sudah sesuai.",
  "thinking_summary": [
    {"step_number": 1, "title": "Memvalidasi dompet asal & tujuan", "detail": "BCA ke GoPay terverifikasi aktif", "status": "completed"}
  ],
  "transaction_draft": {
    "item_count": 1,
    "total_amount_idr": 500000,
    "items": [
      {"title": "Top-up GoPay dari BCA", "amount_idr": 500000, "type": "transfer", "canonical_category": "Transfer", "canonical_main_category": "Transfer", "wallet_name": "BCA", "target_wallet_name": "GoPay"}
    ]
  }
}`,
		},
		{
			Name:          "wallet_balance_inquiry",
			UserPrompt:    "berapa total saldo semua dompetku sekarang?",
			ExpectedTools: `get_user_wallets()`,
			IdealResponseJSON: `{
  "narrative": "Total saldo aktif seluruh dompetmu saat ini adalah Rp 5.250.000, terdiri dari BCA sebesar Rp 5.000.000 dan GoPay sebesar Rp 250.000.",
  "thinking_summary": [
    {"step_number": 1, "title": "Mengambil saldo dompet aktif", "detail": "Menjumlahkan saldo BCA dan GoPay dari database", "status": "completed"}
  ]
}`,
		},
		{
			Name:          "money_flow_sankey_last_month",
			UserPrompt:    "uangku lari ke mana aja bulan lalu?",
			ExpectedTools: `get_cashflow_summary(period="last_month", group_by="income_to_expense_flow")`,
			IdealResponseJSON: `{
  "narrative": "Pada bulan lalu, kamu menghabiskan total Rp 5.942.000 dari 67 transaksi, sementara pemasukan tercatat Rp 10.320.000 (arus kas bersih positif Rp 4.378.000). Rincian terbesar berada pada kategori Household Needs • Rent / Sewa sebesar Rp 2.450.000 (41,2% dari total pengeluaran).",
  "thinking_summary": [
    {"step_number": 1, "title": "Menganalisa aliran kas bulan lalu", "detail": "Menghitung sumber pemasukan dan distribusi pengeluaran dari 67 transaksi", "status": "completed"}
  ],
  "money_flow_card": {
    "period": "last_month",
    "period_label": "October 2026",
    "total_income_idr": 10320000,
    "total_expense_idr": 5942000,
    "net_cashflow_idr": 4378000,
    "transaction_count": 67,
    "income_sources": [{"category": "Income • Salary", "amount": 10320000, "share_pct": 100, "tx_count": 1}],
    "expense_categories": [{"category": "Household Needs • Rent / Sewa", "amount": 2450000, "share_pct": 41.2, "tx_count": 1}],
    "flow_edges": []
  }
}`,
		},
		{
			Name:          "merchant_spending_breakdown_coffee",
			UserPrompt:    "berapa total pengeluaranku buat kopi bulan lalu?",
			ExpectedTools: `get_cashflow_summary(period="last_month", group_by="merchant", keyword_filter="kopi")`,
			IdealResponseJSON: `{
  "narrative": "Kamu menghabiskan Rp 412.000 untuk kopi dari 18 transaksi sepanjang bulan lalu. Seluruh transaksi tercatat melalui dompet GoPay dan BCA pada kategori Food & Beverage • Coffee Shop.",
  "thinking_summary": [
    {"step_number": 1, "title": "Menghitung rincian merchant kopi", "detail": "Agregasi SQL menemukan 18 transaksi kopi senilai Rp 412.000", "status": "completed"}
  ],
  "spending_breakdown_table": {
    "title": "Rincian pengeluaran kopi",
    "period": "last_month",
    "period_label": "October 2026",
    "keyword_filter": "kopi",
    "total_amount_idr": 412000,
    "transaction_count": 18,
    "rows": [
      {"merchant": "Kopi Kenangan", "tx_count": 9, "total_amount": 195000, "wallet_names": ["GoPay"], "categories": ["Food & Beverage • Coffee Shop"]},
      {"merchant": "Fore Coffee", "tx_count": 3, "total_amount": 84000, "wallet_names": ["BCA"], "categories": ["Food & Beverage • Coffee Shop"]}
    ],
    "source_wallets": ["BCA", "GoPay"],
    "categories_used": ["Food & Beverage • Coffee Shop"]
  }
}`,
		},
		{
			Name:          "proactive_budget_after_overspending",
			UserPrompt:    "pengeluaran bulan ini bengkak di makanan, aturin budget makan 1,5jt dong",
			ExpectedTools: `get_cashflow_summary(period="this_month", group_by="category") + get_budget_and_bills_status() + propose_budget_draft(category="Food & Beverage", limit_amount_idr=1500000)`,
			IdealResponseJSON: `{
  "narrative": "Bulan ini pengeluaran Food & Beverage sudah mencapai Rp 1.820.000, lebih tinggi dari rata-rata 30 hari terakhirmu sebesar Rp 1.450.000. Aku siapkan draf batas anggaran Food & Beverage sebesar Rp 1.500.000 untuk kamu aktifkan di bawah.",
  "thinking_summary": [
    {"step_number": 1, "title": "Mengevaluasi belanja makanan", "detail": "Total bulan ini Rp 1.820.000 dibanding rata-rata 30 hari Rp 1.450.000", "status": "completed"},
    {"step_number": 2, "title": "Menyiapkan draf anggaran", "detail": "Kategori Food & Beverage dengan batas Rp 1.500.000", "status": "completed"}
  ],
  "budget_draft": {
    "category": "Food & Beverage",
    "month_year": "2026-11",
    "limit_amount_idr": 1500000,
    "current_month_spend_idr": 1820000,
    "avg_30d_spend_idr": 1450000,
    "is_update": false
  }
}`,
		},
		{
			Name:          "one_shot_goal_draft",
			UserPrompt:    "buatin goal dana darurat 15 juta target 6 bulan lagi, prioritas urgent",
			ExpectedTools: `propose_goal_draft(title="Dana Darurat", target_amount_idr=15000000, months=6, priority="urgent")`,
			IdealResponseJSON: `{
  "narrative": "Draf target Dana Darurat Rp 15.000.000 untuk 6 bulan ke depan sudah siap dengan estimasi tabungan Rp 2.500.000 per bulan.",
  "thinking_summary": [
    {"step_number": 1, "title": "Menghitung jadwal tabungan goal", "detail": "Target Rp 15.000.000 dibagi 6 bulan = Rp 2.500.000/bulan", "status": "completed"}
  ],
  "goal_draft": {
    "title": "Dana Darurat",
    "target_amount_idr": 15000000,
    "saved_amount_idr": 0,
    "remaining_amount_idr": 15000000,
    "months_remaining": 6,
    "monthly_saving_estimate_idr": 2500000,
    "priority": "urgent"
  }
}`,
		},
		{
			Name:          "one_shot_bill_draft",
			UserPrompt:    "ingetin tagihan wifi indihome 385rb jatuh tempo tiap tanggal 20",
			ExpectedTools: `propose_bill_draft(title="Wi-Fi IndiHome", category="Bills & Utilities • Internet & Wi-Fi", amount_idr=385000, due_day=20, frequency="monthly")`,
			IdealResponseJSON: `{
  "narrative": "Draf pengingat tagihan Wi-Fi IndiHome sebesar Rp 385.000 setiap tanggal 20 per bulan sudah aku siapkan di bawah.",
  "thinking_summary": [
    {"step_number": 1, "title": "Menyiapkan jadwal tagihan rutin", "detail": "Tagihan bulanan tanggal 20 dengan kategori Internet & Wi-Fi", "status": "completed"}
  ],
  "bill_draft": {
    "title": "Wi-Fi IndiHome",
    "canonical_category": "Bills & Utilities • Internet & Wi-Fi",
    "canonical_main_category": "Bills & Utilities",
    "amount_idr": 385000,
    "due_day": 20,
    "next_due_date": "2026-11-20",
    "frequency": "monthly",
    "auto_pay": false
  }
}`,
		},
		{
			Name:          "deep_question_paylater_neutral_hint_and_consultants",
			UserPrompt:    "cicilan paylaterku 40% dari gaji, enaknya dilunasin yg mana dulu?",
			ExpectedTools: `get_cashflow_summary(period="this_month", group_by="category") + get_budget_and_bills_status() + match_experts_and_package(main_topic="debt_cashflow", specific_tags=["pinjol", "cashflow"], user_goal_summary="cicilan paylater 40 persen dari gaji ingin strategi pelunasan")`,
			IdealResponseJSON: `{
  "narrative": "Dengan rasio cicilan sekitar 40% dari pemasukan, beban arus kas bulananmu memang sudah melewati batas aman ideal 30%. Secara umum terdapat dua kerangka pelunasan utang: metode Snowball (mendahulukan saldo terkecil agar cepat lega secara psikologis) dan metode Avalanche (mendahulukan bunga tertinggi untuk menekan total biaya bunga), yang masing-masing memiliki trade-off terhadap sisa kas harian. Untuk menetapkan urutan pelunasan yang mengikat sesuai kontrak dan bunga PayLater milikmu, kamu bisa berkonsultasi bersama perencana keuangan berlisensi di bawah.",
  "thinking_summary": [
    {"step_number": 1, "title": "Memeriksa rasio kas & cicilan", "detail": "Mengambil arus kas bulanan dan daftar tagihan aktif", "status": "completed"},
    {"step_number": 2, "title": "Mencocokkan paket & konsultan", "detail": "Memilih Personal Advisory Basic dan praktisi spesialis cashflow & utang", "status": "completed"}
  ]
}`,
		},
		{
			Name:          "external_macro_search_and_kpr_matching",
			UserPrompt:    "suku bunga BI sekarang ngaruh ke cicilan KPR floating aku gak?",
			ExpectedTools: `search_financial_knowledge(query="suku bunga acuan BI Rate terbaru Indonesia") + get_budget_and_bills_status() + match_experts_and_package(main_topic="house_wedding", specific_tags=["kpr"], user_goal_summary="dampak suku bunga BI terhadap cicilan KPR floating")`,
			IdealResponseJSON: `{
  "narrative": "Kenaikan atau penurunan BI-Rate memengaruhi biaya dana perbankan sehingga menjadi acuan penyesuaian bunga KPR floating setelah masa fixed berakhir, meski waktu dan besaran penyesuaiannya bergantung pada klausul kontrak tiap bank. Sebagai gambaran umum, kamu bisa membandingkan porsi cicilan rumah terhadap pemasukan bulanan serta mengevaluasi opsi over-kredit atau percepatan pokok. Untuk simulasi hitungan KPR yang sesuai kontrak kreditmu, silakan diskusikan bersama konsultan berlisensi di bawah.",
  "thinking_summary": [
    {"step_number": 1, "title": "Mencari referensi BI-Rate terkini", "detail": "Mengambil data suku bunga acuan lewat pencarian terisolasi", "status": "completed"},
    {"step_number": 2, "title": "Mencocokkan konsultan KPR", "detail": "Memilih praktisi tier Medium/Premium untuk simulasi KPR", "status": "completed"}
  ]
}`,
		},
		{
			Name:          "context_override_couple_pre_marriage",
			UserPrompt:    "kami bingung cara atur rekening pasutri sebelum nikah dan budget akad",
			ExpectedTools: `match_experts_and_package(target="couple", main_topic="house_wedding", specific_tags=["budget_nikah"], user_goal_summary="atur rekening pasutri sebelum nikah dan budget akad")`,
			IdealResponseJSON: `{
  "narrative": "Sebelum akad, pasangan umumnya mempertimbangkan tiga pola pengelolaan rekening: satu rekening gabungan penuh (transparansi total), pemisahan total dengan patungan pos rutin, atau skema hybrid (satu rekening bersama untuk kebutuhan rumah tangga plus rekening pribadi masing-masing). Setiap pola memiliki kelebihan tergantung perbedaan gaya belanja dan keterbukaan utang bawaan. Untuk merancang kesepakatan rekening dan anggaran pernikahan yang pas bagi kalian berdua, kamu bisa berdiskusi bersama spesialis keuangan pasangan di bawah.",
  "thinking_summary": [
    {"step_number": 1, "title": "Mendeteksi konteks pasangan pranikah", "detail": "Konteks obrolan Couple Pre-Marriage memprioritaskan paket Couple Advisory", "status": "completed"}
  ]
}`,
		},
		{
			Name:          "umkm_tax_separation_and_consultants",
			UserPrompt:    "aturan pajak UMKM 0,5% itu gimana sih, sama cara misahin kas usaha dan pribadi?",
			ExpectedTools: `search_financial_knowledge(query="aturan pajak PPh Final UMKM 0,5 persen PP 55 2022 Indonesia") + match_experts_and_package(target="business", main_topic="sme", specific_tags=["kas_bisnis"], user_goal_summary="aturan pajak UMKM 0,5 persen dan pemisahan kas usaha pribadi")`,
			IdealResponseJSON: `{
  "narrative": "Skema PPh Final 0,5% untuk UMKM berlaku berdasarkan omzet bruto usaha sesuai ketentuan perpajakan yang berlaku, dengan batas omzet tidak kena pajak tertentu bagi wajib pajak orang pribadi serta jangka waktu pemanfaatan tarif final. Untuk pemisahan kas, prinsip dasarnya adalah memisahkan rekening operasional toko dari rekening pribadi, menetapkan gaji pemilik yang rutin, serta mencatat HPP secara konsisten. Agar perhitungan pajak dan pembukuan usahamu sesuai regulasi serta kondisi omzet nyata, kamu bisa berkonsultasi dengan praktisi UMKM & pajak berizin di bawah.",
  "thinking_summary": [
    {"step_number": 1, "title": "Mengambil ketentuan pajak UMKM", "detail": "Mencari referensi aturan PPh Final UMKM 0,5% melalui pencarian terisolasi", "status": "completed"},
    {"step_number": 2, "title": "Mencocokkan konsultan UMKM & pajak", "detail": "Menyiapkan paket UMKM Advisory dan praktisi BKP/CPA", "status": "completed"}
  ]
}`,
		},
	}
}

// FormatFewShotPromptBlock formats few-shot examples into clean text for the cached system prefix.
func FormatFewShotPromptBlock(examples []FewShotExample) string {
	var b strings.Builder
	for i, ex := range examples {
		fmt.Fprintf(&b, "Contoh %d (%s):\n", i+1, ex.Name)
		fmt.Fprintf(&b, "- Input User: %q\n", ex.UserPrompt)
		fmt.Fprintf(&b, "- Tool Pass 1: %s\n", ex.ExpectedTools)
		fmt.Fprintf(&b, "- Output Pass 2 JSON:\n%s\n\n", ex.IdealResponseJSON)
	}
	return strings.TrimSpace(b.String())
}
