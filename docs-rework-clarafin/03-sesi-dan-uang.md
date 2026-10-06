# Mesin sesi dan uang

Semua uang dalam rupiah utuh. Persen dihitung dari harga yang klien bayar, lalu dibulatkan ke rupiah terdekat, sisa pembulatan masuk ke platform.

## Objek

| Objek | Peran |
| --- | --- |
| Slot | Jam praktisi yang `open`, `held`, atau `booked` |
| Hold | Tahanan slot sampai lunas atau kedaluwarsa |
| Order | Tagihan satu paket, atau satu periode Pro |
| Payment | Satu percobaan QRIS dan hasil webhook |
| Session | Janji yang sudah atau belum lunas |
| Closing note | Catatan wajib praktisi kepada klien |
| Payout | Bagian praktisi yang dijadwalkan, ditahan, atau dilepas |
| Complaint | Komplain klien yang menahan pencairan |
| Review | Satu ulasan 1–5 per sesi `completed`, teks opsional |

## Harga satu order sesi

`harga` = harga yang dipasang praktisi untuk paket itu.

`persen_platform` = penimpaan praktisi kalau ada, kalau tidak 20%. Ditolak kalau di luar 10–35%.

`bagian_platform` = bulatkan(`harga` × `persen_platform`).

`bagian_praktisi` = `harga` − `bagian_platform`.

Refund sebagian mengubah `harga` menjadi sisa, lalu kedua bagian dihitung ulang dari sisa. Contoh: harga 100.000, refund 40.000, sisa 60.000, platform 20% dari 60.000.

## Solo

1. Klien memilih paket, praktisi, dan slot `open`.
2. Sistem membuat hold 15 menit dan order `unpaid`. Slot menjadi `held`.
3. QRIS berlaku 15 menit yang sama.
4. Webhook lunas, idempotent pada referensi provider, mengubah order menjadi `paid`, slot menjadi `booked`, sesi menjadi `confirmed`.
5. Untuk virtual, sistem membuat Google Meet dan menyimpan tautannya di sesi.
6. Untuk chat, jendela dimulai pada saat lunas. Panjangnya durasi paket.
7. Lewat 15 menit tanpa webhook lunas: order `expired`, slot kembali `open`, sesi tidak dibuat.

## Couple

1. Pemesan mengundang lewat email. Orang kedua harus punya akun, atau membuat akun lalu menerima.
2. Hold 24 jam. Belum ada tagihan.
3. Kalau tidak diterima dalam 24 jam, hold lepas.
4. Setelah diterima, pemesan membayar harga penuh. Tidak dipecah.
5. Masing-masing akun mengizinkan catatannya sendiri, atau tidak mengizinkan. Sesi tetap `confirmed` kalau salah satu tidak mengizinkan.
6. Satu catatan penutup. Kedua akun bisa membaca.

## Hadir

Berlaku untuk virtual dan tatap muka. Ketukan ada di app. Membuka Meet tidak dihitung hadir.

| Dalam 15 menit dari mulai | Akibat |
| --- | --- |
| Keduanya mengetuk | Sesi berjalan sampai akhir jadwal, lalu `awaiting_notes` |
| Hanya praktisi | Klien tidak hadir. Tidak ada refund. Tetap `awaiting_notes` |
| Hanya klien | Praktisi tidak hadir. Refund penuh. Praktisi tidak dibayar. Catatan tidak wajib |
| Tidak ada yang mengetuk | Refund 80% ke klien. Platform menahan 20% dari fee. Praktisi tidak dibayar. Catatan tidak wajib. Angka 20% ini tidak mengikuti persen khusus praktisi |

## Chat

Tidak ada ketukan Hadir. Tidak bisa dipindah jadwal.

| Kondisi | Akibat |
| --- | --- |
| Praktisi tidak mengirim pesan sampai jendela habis | Sama dengan praktisi tidak hadir. Refund penuh. Catatan tidak wajib |
| Klien boleh batal lebih awal kalau praktisi melewati batas balas-pertama | Refund penuh. Batas awal 12 jam, field CMS |
| Praktisi membalas, klien tidak pernah menulis | Jendela tetap habis. Masuk `awaiting_notes`. Kalau catatan masuk, praktisi dibayar |
| Keduanya menulis | Jendela habis. Masuk `awaiting_notes` |

## Catatan penutup

Wajib supaya uang praktisi bergerak, untuk sesi yang memang menuntut catatan.

Isi:

1. Apa yang dibahas.
2. Langkah 7 hari, minimal satu. Tidak boleh melampaui tag yang tier praktisi boleh tangani.
3. Hal yang sengaja tidak diputuskan. Boleh kosong.

Batas kirim: 24 jam setelah akhir jadwal, atau 24 jam setelah jendela chat habis.

| Kasus | Catatan tidak masuk dalam 24 jam |
| --- | --- |
| Keduanya hadir, atau chat yang praktisinya membalas dan klien juga menulis | Refund penuh. Praktisi tidak dibayar |
| Klien tidak hadir, praktisi hadir, atau chat yang kliennya tidak pernah menulis | Klien tidak di-refund. Praktisi tidak dibayar. Platform menahan fee |
| Praktisi tidak hadir, atau keduanya tidak Hadir | Catatan memang tidak diminta |

Catatan bisa diedit sampai pencairan lepas, lalu terkunci. Klien bisa membaca dan tidak bisa membalas. Email dan push dikirim saat catatan pertama masuk.

Jam 48 jam pencairan dihitung dari pengiriman catatan, bukan dari akhir jadwal.

## Pindah jadwal

Untuk virtual dan tatap muka, klien boleh pindah satu kali, minimal 24 jam sebelum mulai, ke slot `open` praktisi yang sama dan paket yang sama. Batas refund 24 jam dihitung dari jadwal baru. Di dalam 24 jam, pindah tidak bisa. Praktisi tidak bisa memindahkan sepihak. Kalau praktisi tidak bisa hadir, itu pembatalan praktisi: refund penuh.

## Batal oleh klien

| Waktu | Akibat |
| --- | --- |
| 24 jam atau lebih sebelum mulai | Refund penuh. Praktisi tidak dibayar. Slot kembali `open`. Catatan tidak wajib |
| Di bawah 24 jam | Tidak refund. Praktisi dibayar. Catatan tidak wajib, karena sesi dibatalkan sebelum dimulai. Jam 48 jam pencairan dihitung dari saat batal |

Chat mengikuti aturan jendelanya, bukan aturan 24 jam ini.

## Komplain

Klien bisa membuka komplain sejak sesi `confirmed` sampai pencairan lepas. Komplain menahan pencairan. Praktisi boleh mengirim satu tanggapan. Staf memilih satu: refund penuh, refund sebagian, atau lepas pencairan. Tidak ada banding di app.

## Pencairan

Payout `scheduled` pada saat catatan masuk, jatuh tempo 48 jam kemudian. Pada batal klien di bawah 24 jam, jam itu dihitung dari saat batal, karena catatan memang tidak diminta. Komplain membuatnya `held`. Saat lepas, Xendit mengirim `bagian_praktisi` ke rekening yang sedang disetujui. Gagal kirim dicoba ulang. Mengganti rekening saat payout `scheduled` atau `held` menahan kirim sampai staf menyetujui rekening baru.

## Ulasan

Setelah `completed`, klien memberi satu nilai 1–5. Teks boleh kosong. Nilai masuk urutan rekomendasi. Belum ada ulasan ditampilkan sebagai belum ada ulasan, bukan nol.

## Pro

Order terpisah dari sesi. QRIS 15 menit. Lunas membuka 400 aksi selama 30 hari dari webhook. Tidak di-refund. Sisa aksi tidak dibawa. Periode habis tanpa perpanjangan mengembalikan kuota ke 40 aksi per bulan kalender.
