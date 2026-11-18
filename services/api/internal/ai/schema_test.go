package ai_test

import (
	"testing"

	"github.com/clarafin/api/internal/ai"
)

func TestNormalizeNarrativeIDR(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want string
	}{
		{
			name: "preserves decimal with juta scale unit",
			in:   "Cicilan KPR Rp 1,5 juta per bulan.",
			want: "Cicilan KPR Rp 1,5 juta per bulan.",
		},
		{
			name: "preserves dot decimal with jt scale unit",
			in:   "Target dana darurat Rp 2.5 jt bulan ini.",
			want: "Target dana darurat Rp 2.5 jt bulan ini.",
		},
		{
			name: "preserves decimal with rb scale unit",
			in:   "Biaya parkir sekitar Rp 15,5 rb saja.",
			want: "Biaya parkir sekitar Rp 15,5 rb saja.",
		},
		{
			name: "preserves decimal with miliar scale unit",
			in:   "Aset properti senilai Rp 1,5 miliar.",
			want: "Aset properti senilai Rp 1,5 miliar.",
		},
		{
			name: "preserves decimal with milyar, ribu, k, m, t, triliun scale units case-insensitively",
			in:   "Simulasi Rp 1,5 Milyar, Rp 2,5 RIBU, Rp 3,5 K, Rp 4,5 M, Rp 1,2 T, Rp 1,5 triliun.",
			want: "Simulasi Rp 1,5 Milyar, Rp 2,5 RIBU, Rp 3,5 K, Rp 4,5 M, Rp 1,2 T, Rp 1,5 triliun.",
		},
		{
			name: "preserves compact decimal scale units without space",
			in:   "Anggaran Rp 1,5jt dan Rp 2.5jt serta Rp 2000.5jt.",
			want: "Anggaran Rp 1,5jt dan Rp 2.5jt serta Rp 2000.5jt.",
		},
		{
			name: "strips US decimal cents when not followed by scale unit",
			in:   "Total kopi Rp 25000.50.",
			want: "Total kopi Rp 25.000.",
		},
		{
			name: "strips Indonesian decimal cents when not followed by scale unit",
			in:   "Parkir Rp 5000,75 dan saldo Rp 50000,00.",
			want: "Parkir Rp 5.000 dan saldo Rp 50.000.",
		},
		{
			name: "does not treat ordinary words starting with m, k, or t as scale units",
			in:   "Bayar Rp 25000.50 makan siang, Rp 5000,75 kopi, dan Rp 10000,00 tiap hari.",
			want: "Bayar Rp 25.000 makan siang, Rp 5.000 kopi, dan Rp 10.000 tiap hari.",
		},
		{
			name: "preserves canonical thousand dot separators including multi-group millions",
			in:   "Saldo Rp 50.000, Rp 1.500, dan Rp 1.500.000.",
			want: "Saldo Rp 50.000, Rp 1.500, dan Rp 1.500.000.",
		},
		{
			name: "handles mixed scale-unit and standalone tokens in same narrative",
			in:   "Tagihan Rp 1,5 juta dan kopi Rp 25000.50.",
			want: "Tagihan Rp 1,5 juta dan kopi Rp 25.000.",
		},
		{
			name: "normalizes decimal and integer IDR tokens followed by prose punctuation comma",
			in:   "Saldo Rp 8000000.00, detail dan Rp 50000, cek Rp 2,500 serta Rp 1.500,50.",
			want: "Saldo Rp 8.000.000, detail dan Rp 50.000, cek Rp 2,500 serta Rp 1.500.",
		},
		{
			name: "preserves Rp 8000000.00 followed directly by comma prose",
			in:   "Rp 8000000.00, detail",
			want: "Rp 8.000.000, detail",
		},
		{
			name: "breaks inline numbered lists onto newlines while preserving Rupiah amounts and PP numbers",
			in:   "Aku bisa bantu hal berikut: 1. Pencatatan Transaksi Cepat: Catat kopi Rp 25000. 2. Cek Saldo: Pantau Rp 1.500.000. 3. Perencanaan Pajak: Atur sesuai PP 55/2022.",
			want: "Aku bisa bantu hal berikut:\n\n1. Pencatatan Transaksi Cepat: Catat kopi Rp 25.000.\n2. Cek Saldo: Pantau Rp 1.500.000.\n3. Perencanaan Pajak: Atur sesuai PP 55/2022.",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := ai.NormalizeNarrativeIDR(tc.in)
			if got != tc.want {
				t.Fatalf("NormalizeNarrativeIDR(%q) = %q, want %q", tc.in, got, tc.want)
			}
		})
	}
}

func TestFormatNarrativeReadability(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want string
	}{
		{
			name: "formats inline numbered list after colon and periods",
			in:   "Berikut fitur utama: 1. **Pencatatan** harian. 2. **Cek Saldo** real-time. 3. **Perencanaan** anggaran!",
			want: "Berikut fitur utama:\n\n1. **Pencatatan** harian.\n2. **Cek Saldo** real-time.\n3. **Perencanaan** anggaran!",
		},
		{
			name: "leaves Rupiah amounts and regulation numbers untouched",
			in:   "Total pengeluaran Rp 25.000 dan saldo Rp 1.500.000 sesuai PP 55/2022.",
			want: "Total pengeluaran Rp 25.000 dan saldo Rp 1.500.000 sesuai PP 55/2022.",
		},
		{
			name: "does not duplicate newlines when already formatted",
			in:   "Berikut fitur:\n\n1. Pencatatan\n2. Cek Saldo",
			want: "Berikut fitur:\n\n1. Pencatatan\n2. Cek Saldo",
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := ai.FormatNarrativeReadability(tc.in)
			if got != tc.want {
				t.Fatalf("FormatNarrativeReadability(%q) = %q, want %q", tc.in, got, tc.want)
			}
		})
	}
}
