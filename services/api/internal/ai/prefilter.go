package ai

import (
	"strings"
	"unicode"
	"unicode/utf8"
)

const maxGreetingRunes = 80
const maxGreetingTokens = 6
const maxCapabilityRunes = 140
const maxCapabilityTokens = 16

type greetingCategory uint8

const (
	greetingNone greetingCategory = iota
	greetingGeneral
	greetingPagi
	greetingSiang
	greetingSore
	greetingMalam
	greetingSalam
	closingThanks
	closingAck
)

// Defense-in-depth blocklist so financial nouns, amounts, and query words never match as pure greetings.
var blockedFinancialTokens = map[string]struct{}{
	"saldo":       {},
	"uang":        {},
	"duit":        {},
	"kopi":        {},
	"makan":       {},
	"belanja":     {},
	"cicilan":     {},
	"paylater":    {},
	"paylaterku":  {},
	"kpr":         {},
	"budget":      {},
	"goal":        {},
	"goals":       {},
	"tagihan":     {},
	"dompet":      {},
	"wallet":      {},
	"transaksi":   {},
	"pengeluaran": {},
	"pemasukan":   {},
	"gaji":        {},
	"gajian":      {},
	"catat":       {},
	"hitung":      {},
	"rekomendasi": {},
	"konsultan":   {},
	"advisor":     {},
	"praktisi":    {},
	"investasi":   {},
	"beli":        {},
	"bayar":       {},
	"transfer":    {},
	"pinjol":      {},
	"utang":       {},
	"hutang":      {},
	"pajak":       {},
	"tabungan":    {},
	"nabung":      {},
	"rupiah":      {},
	"rp":          {},
	"idr":         {},
	"goceng":      {},
	"gocap":       {},
	"cepek":       {},
	"seceng":      {},
	"ribu":        {},
	"juta":        {},
	"berapa":      {},
	"gimana":      {},
	"bagaimana":   {},
	"kenapa":      {},
	"mengapa":     {},
	"apa":         {},
	"siapa":       {},
	"kapan":       {},
	"tolong":      {},
	"bantu":       {},
	"cek":         {},
	"lihat":       {},
	"buat":        {},
	"buatin":      {},
	"hapus":       {},
	"edit":        {},
}

var singleWordCoreCategories = map[string]greetingCategory{
	"halo":            greetingGeneral,
	"hallo":           greetingGeneral,
	"helo":            greetingGeneral,
	"hello":           greetingGeneral,
	"hai":             greetingGeneral,
	"hi":              greetingGeneral,
	"hey":             greetingGeneral,
	"hei":             greetingGeneral,
	"haai":            greetingGeneral,
	"haloo":           greetingGeneral,
	"pagi":            greetingPagi,
	"siang":           greetingSiang,
	"sore":            greetingSore,
	"malam":           greetingMalam,
	"malem":           greetingMalam,
	"assalamualaikum": greetingSalam,
	"waalaikumsalam":  greetingSalam,
	"makasih":         closingThanks,
	"makasi":          closingThanks,
	"terimakasih":     closingThanks,
	"thanks":          closingThanks,
	"thx":             closingThanks,
	"tq":              closingThanks,
	"ok":              closingAck,
	"oke":             closingAck,
	"okee":            closingAck,
	"okay":            closingAck,
	"okey":            closingAck,
	"sip":             closingAck,
	"siip":            closingAck,
	"siap":            closingAck,
	"mantap":          closingAck,
	"mantul":          closingAck,
	"baik":            closingAck,
	"noted":           closingAck,
	"bye":             closingAck,
	"dadah":           closingAck,
}

var allowedGreetingFillers = map[string]struct{}{
	"ya":       {},
	"yah":      {},
	"yaa":      {},
	"dong":     {},
	"deh":      {},
	"nih":      {},
	"kak":      {},
	"min":      {},
	"clarafin": {},
	"clara":    {},
	"ai":       {},
	"bang":     {},
	"mas":      {},
	"mba":      {},
	"mbak":     {},
	"bro":      {},
	"sis":      {},
	"banyak":   {},
	"banget":   {},
	"bgt":      {},
	"sekali":   {},
	"juga":     {},
	"semua":    {},
}

const capabilityHelpReply = "Halo! Aku Clarafin AI, asisten keuangan pribadimu. Ini yang bisa aku bantu:\n\n" +
	"1. **Catat transaksi & buat dompet** (misal: \"catat kopi 25rb pakai GoPay\")\n" +
	"2. **Analisa arus kas & rincian pengeluaran** bulananmu\n" +
	"3. **Buat target/goal, budget & tagihan** rutin\n" +
	"4. **Edukasi keuangan & pencarian data** transaksi\n" +
	"5. **Rekomendasi konsultan keuangan** sesuai kebutuhanmu\n\n" +
	"Langsung ketik saja apa yang ingin kamu catat atau tanyakan!"

// Exact normalized phrases for capability/help queries that should return a zero-quota overview
// before hitting blockedFinancialTokens (such as "apa" or "bantu").
var capabilityHelpPhrases = map[string]struct{}{
	"apa yang kamu bisa lakukan":  {},
	"apa yang bisa kamu lakukan":  {},
	"kamu bisa apa":               {},
	"kamu bisa apa aja":           {},
	"kamu bisa bantu apa":         {},
	"kamu bisa bantu apa aja":     {},
	"bisa bantu apa":              {},
	"bisa bantu apa aja":          {},
	"fitur apa saja":              {},
	"fitur apa aja":               {},
	"fitur clarafin":              {},
	"cara pakai clarafin":         {},
	"cara pakai":                  {},
	"bantuan":                     {},
	"help":                        {},
}

var capabilityCueSubstrings = []string{
	"kemampuan",
	"bisa kamu lakukan",
	"kamu bisa lakukan",
	"bisa bantu apa",
	"fitur clarafin",
	"fitur apa",
	"kamu bisa apa",
}

// Financial action nouns, verbs, and amount terms that must NOT be intercepted by capability prefilter.
var capabilityBlockedFinancialTokens = map[string]struct{}{
	"saldo":       {},
	"uang":        {},
	"duit":        {},
	"kopi":        {},
	"makan":       {},
	"belanja":     {},
	"cicilan":     {},
	"paylater":    {},
	"paylaterku":  {},
	"kpr":         {},
	"budget":      {},
	"goal":        {},
	"goals":       {},
	"tagihan":     {},
	"dompet":      {},
	"wallet":      {},
	"transaksi":   {},
	"pengeluaran": {},
	"pemasukan":   {},
	"gaji":        {},
	"gajian":      {},
	"catat":       {},
	"hitung":      {},
	"rekomendasi": {},
	"konsultan":   {},
	"advisor":     {},
	"praktisi":    {},
	"investasi":   {},
	"beli":        {},
	"bayar":       {},
	"transfer":    {},
	"pinjol":      {},
	"utang":       {},
	"hutang":      {},
	"pajak":       {},
	"tabungan":    {},
	"nabung":      {},
	"rupiah":      {},
	"rp":          {},
	"idr":         {},
	"goceng":      {},
	"gocap":       {},
	"cepek":       {},
	"seceng":      {},
	"ribu":        {},
	"juta":        {},
	"berapa":      {},
	"cek":         {},
	"lihat":       {},
	"buat":        {},
	"buatin":      {},
	"hapus":       {},
	"edit":        {},
}

func matchesCapabilityQuery(tokens []string) bool {
	if len(tokens) == 0 || len(tokens) > maxCapabilityTokens {
		return false
	}
	joined := strings.Join(tokens, " ")
	if _, exact := capabilityHelpPhrases[joined]; exact {
		return true
	}
	hasCue := false
	for _, cue := range capabilityCueSubstrings {
		if strings.Contains(joined, cue) {
			hasCue = true
			break
		}
	}
	if !hasCue {
		return false
	}
	for _, tok := range tokens {
		if _, blocked := capabilityBlockedFinancialTokens[tok]; blocked {
			return false
		}
	}
	return true
}

// MatchPureGreeting deterministically matches pure Indonesian/English greetings, polite closings,
// and exact/natural capability/help queries in under 2ms so zero-quota responses never hit the LLM.
func MatchPureGreeting(input string) (reply string, matched bool) {
	trimmed := strings.TrimSpace(input)
	runeCount := utf8.RuneCountInString(trimmed)
	if trimmed == "" || runeCount > maxCapabilityRunes {
		return "", false
	}

	for _, r := range trimmed {
		if unicode.IsDigit(r) || r == '%' || r == '$' || r == '=' || r == '<' || r == '>' || r == '/' {
			return "", false
		}
	}

	normalized := strings.ToLower(trimmed)
	normalized = strings.ReplaceAll(normalized, "'", "")
	normalized = strings.ReplaceAll(normalized, "\u2019", "")

	tokens := strings.FieldsFunc(normalized, func(r rune) bool {
		return !unicode.IsLetter(r)
	})
	if len(tokens) == 0 {
		return "", false
	}

	if matchesCapabilityQuery(tokens) {
		return capabilityHelpReply, true
	}

	if runeCount > maxGreetingRunes || len(tokens) > maxGreetingTokens {
		return "", false
	}

	for _, tok := range tokens {
		if _, blocked := blockedFinancialTokens[tok]; blocked {
			return "", false
		}
	}

	var detected greetingCategory
	hasCore := false

	for i := 0; i < len(tokens); {
		if i+1 < len(tokens) {
			if pairCat := matchGreetingPair(tokens[i], tokens[i+1]); pairCat != greetingNone {
				hasCore = true
				detected = pickPreferredCategory(detected, pairCat)
				i += 2
				continue
			}
		}

		if cat, ok := singleWordCoreCategories[tokens[i]]; ok {
			hasCore = true
			detected = pickPreferredCategory(detected, cat)
			i++
			continue
		}

		if _, ok := allowedGreetingFillers[tokens[i]]; ok {
			i++
			continue
		}

		return "", false
	}

	if !hasCore {
		return "", false
	}

	return replyForGreetingCategory(detected), true
}

func matchGreetingPair(first, second string) greetingCategory {
	switch {
	case first == "selamat" && second == "pagi":
		return greetingPagi
	case first == "selamat" && second == "siang":
		return greetingSiang
	case first == "selamat" && second == "sore":
		return greetingSore
	case first == "selamat" && (second == "malam" || second == "malem"):
		return greetingMalam
	case first == "assalamu" && second == "alaikum":
		return greetingSalam
	case first == "terima" && second == "kasih":
		return closingThanks
	case first == "thank" && second == "you":
		return closingThanks
	case first == "sama" && second == "sama":
		return closingAck
	case first == "sampai" && second == "jumpa":
		return closingAck
	default:
		return greetingNone
	}
}

func pickPreferredCategory(current, candidate greetingCategory) greetingCategory {
	if current == greetingNone {
		return candidate
	}
	// Prefer specific time-of-day/salam greetings over generic halo, and thanks over plain ok.
	if current == greetingGeneral && candidate != greetingGeneral {
		return candidate
	}
	if current == closingAck && candidate == closingThanks {
		return candidate
	}
	return current
}

func replyForGreetingCategory(cat greetingCategory) string {
	switch cat {
	case greetingSalam:
		return "Waalaikumsalam! Ada yang bisa Clarafin AI bantu hari ini? Kamu bisa catat transaksi, cek saldo dompet, atau tanya seputar rencana keuanganmu."
	case greetingPagi:
		return "Selamat pagi! Ada yang bisa Clarafin AI bantu hari ini? Kamu bisa catat pengeluaran, cek ringkasan kas, atau buat target keuangan."
	case greetingSiang:
		return "Selamat siang! Ada yang bisa Clarafin AI bantu? Ketik transaksi yang ingin dicatat atau tanyakan kondisi keuanganmu."
	case greetingSore:
		return "Selamat sore! Ada yang bisa Clarafin AI bantu? Kamu bisa catat transaksi harian atau cek progres anggaranmu di sini."
	case greetingMalam:
		return "Selamat malam! Ada yang bisa Clarafin AI bantu hari ini? Kamu bisa catat pengeluaran hari ini atau tanyakan rincian keuanganmu."
	case closingThanks:
		return "Sama-sama! Kabari saja kalau ada transaksi yang mau dicatat atau hal keuangan lain yang ingin kamu cek."
	case closingAck:
		return "Siap! Kalau ada transaksi atau pertanyaan keuangan lain, langsung tulis di sini ya."
	default:
		return "Halo! Aku Clarafin AI. Kamu bisa langsung ketik transaksi untuk dicatat, cek saldo dan anggaran, atau tanya topik keuangan."
	}
}
