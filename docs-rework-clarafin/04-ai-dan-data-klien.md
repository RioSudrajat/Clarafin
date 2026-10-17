# AI, tracker, dan data klien

## Tracker pada launch

Yang wajib jalan: beberapa dompet, transaksi manual, kategori dari CMS, dan ringkasan pemasukan lawan pengeluaran bulan berjalan. Mata uang hanya IDR.

Goals, budget, dan tagihan boleh tetap ada di aplikasi yang sudah ditulis. Mereka bukan syarat launch.

Pengguna baru mengisi nama dan tanggal lahir, lalu mendarat di daftar konsultan. Dompet tidak dipaksa di langkah pertama.

Setiap transaksi yang berasal dari AI masuk sebagai draf. Saldo baru berubah setelah klien mengonfirmasi.

## Aksi dan kuota

Satu aksi adalah satu permintaan yang memanggil model atau sapuan Gmail.

| Peristiwa | Aksi |
| --- | --- |
| Perintah catat dari teks | 1 |
| Satu foto nota, termasuk yang gagal dibaca | 1 |
| Satu sapuan Gmail, berapa pun resi yang diusulkan | 1 |
| Satu jawaban analisa | 1 |
| Mengonfirmasi draf | 0 |
| Sapaan, dan konfirmasi bahwa catatan sudah tersimpan | 0 |

Gratis: 40 aksi per bulan kalender. Pro: 400 aksi per 30 hari sejak lunas. Kuota habis menolak aksi baru dan menawarkan Pro. Tidak ada paket tanpa batas.

## Yang boleh dijawab

AI boleh menghitung dan menggambarkan angka milik klien: cicilan dibanding gaji, sisa setelah tagihan, nota yang masuk ke kategori, pola 30–90 hari dari transaksi yang sudah dikonfirmasi.

AI boleh mencatat pengeluaran dari kalimat dan dari foto nota.

AI boleh menyapu Gmail dengan aturan di bawah.

AI boleh menyebut satu sampai tiga praktisi.

## Yang tidak boleh dijawab

AI berhenti, tanpa menyisipkan langkah solusi, lalu menawarkan praktisi, kalau pertanyaan masuk ke salah satu ini:

- Restrukturisasi utang, urutan pelunasan, atau negosiasi kreditur
- Rancangan runway
- Rekomendasi produk investasi, asuransi, atau instrumen lain
- Rencana keuangan yang memilih tindakan untuk klien

Kalimat umum seperti "biasanya utang bunga tertinggi didahulukan" termasuk saran, jadi ikut berhenti.

Contoh yang masih boleh: "Cicilanmu 62% dari gaji bulan ini. Sisa setelah tagihan Rp1.200.000." Lalu tawaran praktisi.

Contoh yang berhenti: "Lunasi utang A dulu, lalu ajukan restrukturisasi ke bank." Diganti satu kalimat batas, lalu satu sampai tiga praktisi.

## Kapan tawaran praktisi muncul

Muncul di akhir jawaban analisa, dan menjadi seluruh penutup saat pertanyaan menyeberang batas.

Tidak muncul setelah sapaan. Tidak muncul setelah "catat 20 ribu kopi" yang berhasil menjadi draf atau transaksi.

## Urutan satu sampai tiga nama

1. Tag masalah yang diminta klien.
2. Buang praktisi yang tier-nya tidak boleh menangani tag itu.
3. Buang yang tidak punya paket aktif untuk kanal yang diminta.
4. Buang yang tidak punya slot dalam 14 hari.
5. Taruh sematan staf untuk tag itu di atas, maksimal 3, dan hanya yang lolos saringan. Sematan yang tidak lolos diabaikan.
6. Sisanya diurutkan slot paling cepat, lalu rating, lalu jumlah sesi selesai.

Bukan berdasarkan persen platform. Bukan berdasarkan harga termurah.

## Gmail

Klien menyambungkan sendiri. Akses baca saja. Hanya 30 hari terakhir. Hanya pesan yang lolos saringan resi dan pembayaran. Yang disimpan setelah klien mengonfirmasi tiap draf: nominal, merchant, dan tanggal. Isi email mentah tidak disimpan. Memutus sambungan menghapus token. Transaksi yang sudah dikonfirmasi tetap ada.

## Izin catatan ke praktisi

Default tertutup. Per sesi, klien memilih rentang tanggal dan dompet. Bukan per transaksi, dan bukan seluruh akun untuk selamanya.

Sebelum mengizinkan, layar menyatakan bahwa praktisi akan melihat angka itu, dan gambaran sesi bisa lebih tajam kalau yang dibuka lebih lengkap. Risiko membuka ada pada klien.

Izin aktif sejak order sesi `paid` sampai 7 hari setelah sesi berakhir, atau sampai klien mencabut, mana yang lebih dulu. Mencabut langsung menutup akses. Couple: masing-masing akun punya izinnya sendiri. Catatan penutup tetap terlihat kedua akun, karena itu keluaran sesi, bukan isi dompet.

## Hapus akun

Dari app. Yang terjadi segera:

- Login akun itu mati
- Token Gmail, draf belum dikonfirmasi, dan riwayat obrolan AI dihapus
- Izin yang masih aktif dicabut
- Ulasan disamarkan

Yang diarsip 5 tahun, hanya untuk staf keuangan dan kepatuhan, tidak tampil di app, dan tidak bisa dibuka praktisi:

- Profil
- Tracker
- Transkrip sesi dengan konsultan
- Order, refund, dan pencairan

Daftar lagi dengan email yang sama membuat akun kosong. Arsip tidak dikembalikan. Menghapus akun tidak menghapus data pasangan couple. Praktisi tidak bisa menghapus akun selama ada sesi yang belum selesai atau pencairan yang belum lepas.

## Pemberitahuan

Email, push, dan daftar di app membawa peristiwa yang sama: lunas, pengingat H-1, pengingat 1 jam sebelum sesi, catatan penutup masuk, refund, dan hasil komplain. Ketukan push membuka sesi atau pembayaran itu.
