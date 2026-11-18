package ai_test

import (
	"strings"
	"testing"
	"time"

	"github.com/clarafin/api/internal/ai"
)

func TestMatchPureGreeting_PositiveCases(t *testing.T) {
	cases := []struct {
		name  string
		input string
	}{
		{name: "halo exclamation", input: "Halo!"},
		{name: "lowercase hai", input: "hai"},
		{name: "halo clarafin", input: "halo clarafin"},
		{name: "selamat pagi", input: "Selamat pagi"},
		{name: "pagi only", input: "pagi"},
		{name: "siang only", input: "siang"},
		{name: "sore only", input: "sore"},
		{name: "malam only", input: "malam"},
		{name: "assalamualaikum", input: "assalamualaikum"},
		{name: "assalamu alaikum apostrophe", input: "Assalamu'alaikum!"},
		{name: "makasih ya", input: "makasih ya"},
		{name: "terima kasih", input: "terima kasih"},
		{name: "terima kasih banyak", input: "Terima kasih banyak ya"},
		{name: "thanks", input: "thanks"},
		{name: "thank you", input: "Thank you"},
		{name: "ok", input: "ok"},
		{name: "oke", input: "oke"},
		{name: "sip", input: "sip"},
		{name: "mantap", input: "mantap"},
		{name: "whitespace padded", input: "   Halo!!   "},
		{name: "capability apa yang kamu bisa lakukan", input: "Apa yang kamu bisa lakukan?"},
		{name: "capability kamu bisa bantu apa aja", input: "  kamu bisa bantu apa aja?! "},
		{name: "capability fitur clarafin", input: "fitur clarafin"},
		{name: "capability help", input: "help"},
		{name: "capability natural indonesian bro", input: "Apa aja sih bro kemampuan yang bisa kamu lakukan sebagai ai clarafin ini?"},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			reply, matched := ai.MatchPureGreeting(tc.input)
			if !matched {
				t.Fatalf("MatchPureGreeting(%q) matched=false, want true", tc.input)
			}
			if strings.TrimSpace(reply) == "" {
				t.Fatalf("MatchPureGreeting(%q) returned empty reply", tc.input)
			}
			if strings.Contains(reply, "\u2014") {
				t.Fatalf("MatchPureGreeting(%q) reply contains forbidden em dash: %q", tc.input, reply)
			}
		})
	}
}

func TestMatchPureGreeting_RejectsMixedAmountsAndFinancialIntents(t *testing.T) {
	cases := []struct {
		name  string
		input string
	}{
		{name: "empty", input: ""},
		{name: "whitespace", input: "   \t\n  "},
		{name: "halo saldo bca", input: "halo berapa saldo BCA?"},
		{name: "pagi catat kopi 25rb", input: "pagi, catat kopi 25rb"},
		{name: "halo 50k", input: "halo 50k"},
		{name: "makasih 40 percent cicilan", input: "makasih, cicilan paylaterku 40% dari gaji gimana?"},
		{name: "halo cek uang dompet", input: "halo cek uang di dompet"},
		{name: "siang beli makan", input: "siang, beli makan 35000"},
		{name: "oke belanja", input: "oke belanja bulanan"},
		{name: "mantap hitung kpr", input: "mantap hitung KPR"},
		{name: "sip budget goal tagihan", input: "sip atur budget goal dan tagihan"},
		{name: "halo transaksi pengeluaran", input: "halo lihat transaksi pengeluaran gaji"},
		{name: "hai rekomendasi konsultan", input: "hai minta rekomendasi konsultan investasi"},
		{name: "halo question apa kabar", input: "halo apa kabar?"},
		{name: "incomplete selamat", input: "selamat"},
		{name: "incomplete terima", input: "terima"},
		{name: "lone filler", input: "ya"},
		{name: "financial question apa itu inflasi", input: "apa itu inflasi"},
		{name: "financial question apa saldo BCA ku", input: "apa saldo BCA ku"},
		{name: "financial question berapa saldo saya", input: "berapa saldo saya"},
		{name: "financial question berapa pengeluaran kopi bulan ini", input: "Berapa pengeluaran kopi bulan ini?"},
		{name: "capability phrase with financial noun utang", input: "apa yang bisa kamu lakukan untuk melunasi utang paylater?"},
		{name: "transaction catat kopi 25k", input: "catat kopi 25k"},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			reply, matched := ai.MatchPureGreeting(tc.input)
			if matched {
				t.Fatalf("MatchPureGreeting(%q) matched=true (reply=%q), want false", tc.input, reply)
			}
			if reply != "" {
				t.Fatalf("MatchPureGreeting(%q) expected empty reply when unmatched, got %q", tc.input, reply)
			}
		})
	}
}

func TestMatchPureGreeting_LatencyUnder2ms(t *testing.T) {
	inputs := []string{
		"Halo!",
		"pagi, catat kopi 25rb pake gopay",
		"makasih ya",
		"cicilan paylaterku 40% dari gaji, enaknya dilunasin yg mana dulu?",
	}

	const iterations = 1000
	start := time.Now()
	for i := 0; i < iterations; i++ {
		for _, in := range inputs {
			_, _ = ai.MatchPureGreeting(in)
		}
	}
	elapsed := time.Since(start)
	perCall := elapsed / time.Duration(iterations*len(inputs))
	if perCall >= 2*time.Millisecond {
		t.Fatalf("MatchPureGreeting average latency %v exceeded 2ms budget", perCall)
	}
}
