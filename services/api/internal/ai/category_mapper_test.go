package ai_test

import (
	"testing"

	"github.com/clarafin/api/internal/ai"
)

func TestNormalizeCanonicalCategory_RequiredAliasesAndVerbatimCatalog(t *testing.T) {
	validIncomeCategories := map[string]string{
		"Income":                                  "Income",
		"Income • Salary":                         "Income",
		"Income • Bonus":                          "Income",
		"Income • Pocket Money":                   "Income",
		"Income • Additional Income":              "Income",
		"Business":                                "Business",
		"Business • Sales Revenue":                "Business",
		"Business • Freelance & Client":           "Business",
		"Investment":                              "Investment",
		"Investment • Dividends":                  "Investment",
		"Investment • Capital Gains":              "Investment",
		"Investment • Bank Interest":              "Investment",
		"Gift":                                    "Gift",
		"Gift • From Family":                      "Gift",
		"Gift • Rewards / Cashback":               "Gift",
		"Loans":                                   "Loans",
		"Loans • Bank Loan":                       "Loans",
		"Loans • Personal Borrowing":              "Loans",
		"Incoming Transfer":                       "Incoming Transfer",
		"Incoming Transfer • Inter-Bank Transfer": "Incoming Transfer",
		"Incoming Transfer • E-Wallet Top-up":     "Incoming Transfer",
	}

	validExpenseCategories := map[string]string{
		"Food & Beverage":                               "Food & Beverage",
		"Food & Beverage • Restaurant":                  "Food & Beverage",
		"Food & Beverage • Food delivery":               "Food & Beverage",
		"Food & Beverage • Coffee Shop":                 "Food & Beverage",
		"Food & Beverage • Fast Food":                   "Food & Beverage",
		"Food & Beverage • Alcoholic Beverages":         "Food & Beverage",
		"Food & Beverage • Bakery & Cake Shop":          "Food & Beverage",
		"Transportation":                                "Transportation",
		"Transportation • Public Transport":             "Transportation",
		"Transportation • Ride Hailing / Taxi":          "Transportation",
		"Transportation • Fuel & Gas":                   "Transportation",
		"Transportation • Parking & Toll":               "Transportation",
		"Transportation • Vehicle Maintenance":          "Transportation",
		"Household Needs":                               "Household Needs",
		"Household Needs • Groceries / Belanja Dapur":   "Household Needs",
		"Household Needs • Cleaning Supplies":           "Household Needs",
		"Household Needs • Home Repair":                 "Household Needs",
		"Household Needs • Rent / Sewa":                 "Household Needs",
		"Bills & Utilities":                             "Bills & Utilities",
		"Bills & Utilities • Electricity / Listrik PLN": "Bills & Utilities",
		"Bills & Utilities • Water / Air PDAM":          "Bills & Utilities",
		"Bills & Utilities • Internet & Wi-Fi":          "Bills & Utilities",
		"Bills & Utilities • Phone & Mobile Data":       "Bills & Utilities",
		"Bills & Utilities • Digital Subscriptions":     "Bills & Utilities",
		"Pets":                                         "Pets",
		"Pets • Pet Food":                              "Pets",
		"Pets • Veterinary / Dokter":                   "Pets",
		"Pets • Grooming & Toys":                       "Pets",
		"Family":                                       "Family",
		"Family • Childcare & Needs":                   "Family",
		"Family • Allowance to Parents":                "Family",
		"Family • Family Events":                       "Family",
		"Shopping":                                     "Shopping",
		"Shopping • Clothing & Fashion":                "Shopping",
		"Shopping • Electronics & Gadgets":             "Shopping",
		"Shopping • Beauty & Skincare":                 "Shopping",
		"Shopping • Shoes & Accessories":               "Shopping",
		"Health & Sports":                              "Health & Sports",
		"Health & Sports • Doctor & Hospital":          "Health & Sports",
		"Health & Sports • Medicine & Pharmacy":        "Health & Sports",
		"Health & Sports • Gym & Fitness Membership":   "Health & Sports",
		"Health & Sports • Sports Equipment":           "Health & Sports",
		"Donations & Gifts":                            "Donations & Gifts",
		"Donations & Gifts • Charity & Infaq":          "Donations & Gifts",
		"Donations & Gifts • Gifts & Presents":         "Donations & Gifts",
		"Donations & Gifts • Zakat":                    "Donations & Gifts",
		"Travel":                                       "Travel",
		"Travel • Flight & Train Tickets":              "Travel",
		"Travel • Hotel & Lodging":                     "Travel",
		"Travel • Attractions & Tours":                 "Travel",
		"Entertainment":                                "Entertainment",
		"Entertainment • Cinema & Movies":              "Entertainment",
		"Entertainment • Games & Top-up":               "Entertainment",
		"Entertainment • Concerts & Events":            "Entertainment",
		"Entertainment • Hobbies & Crafts":             "Entertainment",
		"Education":                                    "Education",
		"Education • Courses & Certification":          "Education",
		"Education • Books & Stationery":               "Education",
		"Education • Tuition / SPP":                    "Education",
		"Loans":                                        "Loans",
		"Loans • Mortgage / KPR":                       "Loans",
		"Loans • Vehicle Installment":                  "Loans",
		"Loans • Personal Loan":                        "Loans",
		"Loans • Credit Card Bill":                     "Loans",
		"Investment":                                   "Investment",
		"Investment • Stocks / Saham":                  "Investment",
		"Investment • Mutual Funds / Reksadana":        "Investment",
		"Investment • Crypto Assets":                   "Investment",
		"Investment • Gold / Emas":                     "Investment",
		"Business":                                     "Business",
		"Business • Operations & Utilities":            "Business",
		"Business • Inventory & Supplies":              "Business",
		"Business • Marketing & Ads":                   "Business",
		"Other Financial Expenses":                     "Other Financial Expenses",
		"Other Financial Expenses • Bank Admin Fees":   "Other Financial Expenses",
		"Other Financial Expenses • Taxes / Pajak":     "Other Financial Expenses",
		"Other Financial Expenses • Insurance Premium": "Other Financial Expenses",
		"Other Services":                               "Other Services",
		"Other Services • Laundry":                     "Other Services",
		"Other Services • Salon & Barbershop":          "Other Services",
		"Other Services • Repair & Tech Services":      "Other Services",
		"Other Services • Courier & Postage":           "Other Services",
		"Others":                                       "Others",
		"Others • General Uncategorized":               "Others",
	}

	cases := []struct {
		name        string
		rawCategory string
		txType      string
		contextHint string
		wantCat     string
		wantMain    string
		wantType    string
		wantFallbk  bool
	}{
		{
			name:        "indonesian makanan main category",
			rawCategory: "Makanan",
			txType:      "expense",
			wantCat:     "Food & Beverage",
			wantMain:    "Food & Beverage",
			wantType:    "expense",
		},
		{
			name:        "lowercase makan alias",
			rawCategory: "makan",
			txType:      "expense",
			wantCat:     "Food & Beverage",
			wantMain:    "Food & Beverage",
			wantType:    "expense",
		},
		{
			name:        "kopi kenangan alias",
			rawCategory: "kopi kenangan",
			txType:      "expense",
			wantCat:     "Food & Beverage • Coffee Shop",
			wantMain:    "Food & Beverage",
			wantType:    "expense",
		},
		{
			name:        "starbucks alias",
			rawCategory: "starbucks",
			txType:      "expense",
			wantCat:     "Food & Beverage • Coffee Shop",
			wantMain:    "Food & Beverage",
			wantType:    "expense",
		},
		{
			name:        "fore coffee alias",
			rawCategory: "fore",
			txType:      "expense",
			wantCat:     "Food & Beverage • Coffee Shop",
			wantMain:    "Food & Beverage",
			wantType:    "expense",
		},
		{
			name:        "gofood delivery alias",
			rawCategory: "gofood",
			txType:      "expense",
			wantCat:     "Food & Beverage • Food delivery",
			wantMain:    "Food & Beverage",
			wantType:    "expense",
		},
		{
			name:        "grabfood delivery alias",
			rawCategory: "grabfood",
			txType:      "expense",
			wantCat:     "Food & Beverage • Food delivery",
			wantMain:    "Food & Beverage",
			wantType:    "expense",
		},
		{
			name:        "warteg restaurant alias",
			rawCategory: "warteg",
			txType:      "expense",
			wantCat:     "Food & Beverage • Restaurant",
			wantMain:    "Food & Beverage",
			wantType:    "expense",
		},
		{
			name:        "parkir alias",
			rawCategory: "parkir",
			txType:      "expense",
			wantCat:     "Transportation • Parking & Toll",
			wantMain:    "Transportation",
			wantType:    "expense",
		},
		{
			name:        "e-toll alias",
			rawCategory: "e-toll",
			txType:      "expense",
			wantCat:     "Transportation • Parking & Toll",
			wantMain:    "Transportation",
			wantType:    "expense",
		},
		{
			name:        "tol alias",
			rawCategory: "tol",
			txType:      "expense",
			wantCat:     "Transportation • Parking & Toll",
			wantMain:    "Transportation",
			wantType:    "expense",
		},
		{
			name:        "ojol alias",
			rawCategory: "ojol",
			txType:      "expense",
			wantCat:     "Transportation • Ride Hailing / Taxi",
			wantMain:    "Transportation",
			wantType:    "expense",
		},
		{
			name:        "transportasi alias",
			rawCategory: "Transportasi",
			txType:      "expense",
			wantCat:     "Transportation • Ride Hailing / Taxi",
			wantMain:    "Transportation",
			wantType:    "expense",
		},
		{
			name:        "gojek alias",
			rawCategory: "gojek",
			txType:      "expense",
			wantCat:     "Transportation • Ride Hailing / Taxi",
			wantMain:    "Transportation",
			wantType:    "expense",
		},
		{
			name:        "bensin alias",
			rawCategory: "bensin",
			txType:      "expense",
			wantCat:     "Transportation • Fuel & Gas",
			wantMain:    "Transportation",
			wantType:    "expense",
		},
		{
			name:        "pertamax alias",
			rawCategory: "pertamax",
			txType:      "expense",
			wantCat:     "Transportation • Fuel & Gas",
			wantMain:    "Transportation",
			wantType:    "expense",
		},
		{
			name:        "tagihan main category",
			rawCategory: "Tagihan",
			txType:      "expense",
			wantCat:     "Bills & Utilities",
			wantMain:    "Bills & Utilities",
			wantType:    "expense",
		},
		{
			name:        "listrik subcategory",
			rawCategory: "listrik",
			txType:      "expense",
			wantCat:     "Bills & Utilities • Electricity / Listrik PLN",
			wantMain:    "Bills & Utilities",
			wantType:    "expense",
		},
		{
			name:        "internet subcategory",
			rawCategory: "internet",
			txType:      "expense",
			wantCat:     "Bills & Utilities • Internet & Wi-Fi",
			wantMain:    "Bills & Utilities",
			wantType:    "expense",
		},
		{
			name:        "gaji income alias",
			rawCategory: "gaji",
			txType:      "income",
			wantCat:     "Income • Salary",
			wantMain:    "Income",
			wantType:    "income",
		},
		{
			name:        "salary income alias",
			rawCategory: "salary",
			txType:      "income",
			wantCat:     "Income • Salary",
			wantMain:    "Income",
			wantType:    "income",
		},
		{
			name:        "belanja main category",
			rawCategory: "Belanja",
			txType:      "expense",
			wantCat:     "Shopping",
			wantMain:    "Shopping",
			wantType:    "expense",
		},
		{
			name:        "hiburan main category",
			rawCategory: "Hiburan",
			txType:      "expense",
			wantCat:     "Entertainment",
			wantMain:    "Entertainment",
			wantType:    "expense",
		},
		{
			name:        "kesehatan main category",
			rawCategory: "Kesehatan",
			txType:      "expense",
			wantCat:     "Health & Sports",
			wantMain:    "Health & Sports",
			wantType:    "expense",
		},
		{
			name:        "unknown expense fallback",
			rawCategory: "unknown_xyz_123",
			txType:      "expense",
			wantCat:     "Others • General Uncategorized",
			wantMain:    "Others",
			wantType:    "expense",
			wantFallbk:  true,
		},
		{
			name:        "unknown income fallback",
			rawCategory: "unknown_income_xyz",
			txType:      "income",
			wantCat:     "Income • Additional Income",
			wantMain:    "Income",
			wantType:    "income",
			wantFallbk:  true,
		},
		{
			name:        "transfer type maps to Transfer",
			rawCategory: "",
			txType:      "transfer",
			contextHint: "Topup GoPay",
			wantCat:     "Transfer",
			wantMain:    "Transfer",
			wantType:    "transfer",
		},
		{
			name:        "parent category refined by context hint",
			rawCategory: "Makanan",
			txType:      "expense",
			contextHint: "Kopi Kenangan",
			wantCat:     "Food & Beverage • Coffee Shop",
			wantMain:    "Food & Beverage",
			wantType:    "expense",
		},
		{
			name:        "empty raw category inferred from context hint",
			rawCategory: "",
			txType:      "expense",
			contextHint: "Parkir Mall Grand Indonesia",
			wantCat:     "Transportation • Parking & Toll",
			wantMain:    "Transportation",
			wantType:    "expense",
		},
		{
			name:        "word boundary safety avoids tol inside botol",
			rawCategory: "",
			txType:      "expense",
			contextHint: "Botol Air Mineral",
			wantCat:     "Food & Beverage",
			wantMain:    "Food & Beverage",
			wantType:    "expense",
		},
		{
			name:        "investment disambiguated for income vs expense",
			rawCategory: "Investment",
			txType:      "income",
			wantCat:     "Investment",
			wantMain:    "Investment",
			wantType:    "income",
		},
		{
			name:        "investment disambiguated for expense",
			rawCategory: "Investment",
			txType:      "expense",
			wantCat:     "Investment",
			wantMain:    "Investment",
			wantType:    "expense",
		},
		{
			name:        "others upgraded by context hint",
			rawCategory: "lainnya",
			txType:      "expense",
			contextHint: "Kopi Kenangan",
			wantCat:     "Food & Beverage • Coffee Shop",
			wantMain:    "Food & Beverage",
			wantType:    "expense",
		},
		{
			name:        "unknown xyz with income type falls back to Income Additional Income",
			rawCategory: "unknown_xyz",
			txType:      "income",
			wantCat:     "Income • Additional Income",
			wantMain:    "Income",
			wantType:    "income",
			wantFallbk:  true,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := ai.NormalizeCanonicalCategory(tc.rawCategory, tc.txType, tc.contextHint)
			if got.CanonicalCategory != tc.wantCat {
				t.Fatalf("CanonicalCategory = %q, want %q (full=%+v)", got.CanonicalCategory, tc.wantCat, got)
			}
			if got.CanonicalMainCategory != tc.wantMain {
				t.Fatalf("CanonicalMainCategory = %q, want %q", got.CanonicalMainCategory, tc.wantMain)
			}
			if got.Type != tc.wantType {
				t.Fatalf("Type = %q, want %q", got.Type, tc.wantType)
			}
			if got.IsFallback != tc.wantFallbk {
				t.Fatalf("IsFallback = %v, want %v", got.IsFallback, tc.wantFallbk)
			}

			switch got.Type {
			case "income":
				if main, ok := validIncomeCategories[got.CanonicalCategory]; !ok || main != got.CanonicalMainCategory {
					t.Fatalf("income category %q (main %q) is not verbatim in TransactionCategories", got.CanonicalCategory, got.CanonicalMainCategory)
				}
			case "expense":
				if main, ok := validExpenseCategories[got.CanonicalCategory]; !ok || main != got.CanonicalMainCategory {
					t.Fatalf("expense category %q (main %q) is not verbatim in TransactionCategories", got.CanonicalCategory, got.CanonicalMainCategory)
				}
			case "transfer":
				if got.CanonicalCategory != "Transfer" && validIncomeCategories[got.CanonicalCategory] == "" {
					t.Fatalf("transfer category %q is invalid", got.CanonicalCategory)
				}
			default:
				t.Fatalf("unexpected Type %q", got.Type)
			}
		})
	}
}
