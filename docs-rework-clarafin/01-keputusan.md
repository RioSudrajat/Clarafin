# Keputusan terkunci

Sumber percakapan perancangan 5–6 Oktober 2026. Harga dan kombinasi paket yang tidak ada di sheet bisnis tidak dikarang. Sheet sumber: `Package Price.xlsx` dari tim bisnis.

## Produk

Clarafin menjual sesi dengan manusia. Tracker uang gratis, dipakai untuk menarik pengguna dan menjadi bahan sesi. AI adalah asisten berkuota, bukan konsultan.

Yang berbayar pada launch: sesi manusia, dan langganan Pro untuk menaikkan kuota AI. Pro tidak mendiskon harga sesi.

Nama produk pada dokumen baru adalah Clarafin. Dokumen lama yang menulis HaloFin tidak diubah.

## Siapa memakai apa

Satu aplikasi Flutter. Satu akun bisa menjadi klien dan praktisi. UI praktisi tidak ada sebelum staf menyetujui pendaftaran di CMS.

Pendaftaran praktisi dari akun klien. Yang diunggah: KTP, ijazah atau sertifikat sesuai tier, dan rekening yang nama pemiliknya sama dengan KTP. Pencairan hanya ke rekening itu. Mengganti rekening menunggu persetujuan staf sebelum pencairan berikutnya.

Tanggal lahir wajib saat daftar. Empat batas umur di CMS kosong pada hari pertama, artinya tidak ada batas: daftar, bayar sesi dan Pro, sambung Gmail, buka catatan ke konsultan. Praktisi tidak memakai angka itu. Praktisi tetap harus punya KTP dan lolos persetujuan.

Antarmuka bahasa Indonesia. Jadwal ditampilkan di Asia/Jakarta. Instant disimpan UTC.

## Supply

Tier, paket, durasi, plafon harga, venue, kategori pengeluaran, tag masalah, batas umur, dan persen platform adalah data CMS. Mengubahnya tidak perlu rilis aplikasi.

Staf Clarafin mengedit CMS lewat web internal. Praktisi tidak mengubah tier, plafon, venue, atau persen dasar. Praktisi memilih paket aktif dan memasang harga di antara dasar dan maksimum.

Ada satu peran staf pada launch. Peran itu bisa menyetujui praktisi, mengubah katalog, menahan pencairan, dan memutuskan komplain.

Isi awal katalog disalin dari sheet bisnis. Paket tanpa harga dasar dan harga maksimum tidak dijual. Rinciannya di [02-katalog.md](./02-katalog.md).

## Uang

Klien membayar harga yang tertera. Harga itu sudah termasuk bagian platform.

Default platform 20% dari harga yang benar-benar dibayar, praktisi 80%. Staf boleh menimpa persen satu praktisi di antara 10% dan 35%. Praktisi yang dinilai kuat mendapat potongan platform yang lebih rendah. Yang lemah sebaliknya. Aturan otomatis berdasarkan rating dan volume ditunda. Tidak ada perhitungan dari harga maksimum di sheet.

Bayar yang hidup pada launch: QRIS lewat Xendit, berlaku 15 menit, sama dengan tahan slot solo. Virtual account dan e-wallet ada di kode, tidak muncul di checkout sampai pembayaran ujung-ke-ujungnya selesai. Kartu dan perpanjangan Pro otomatis ditunda sampai keduanya hidup di produksi.

Pro Rp49.000 untuk 400 aksi selama 30 hari. Diperpanjang manual lewat QRIS. Tidak ada potong otomatis. Tidak bisa di-refund setelah lunas. Aksi yang tersisa hangus di akhir periode. Tanpa Pro, kuota 40 aksi per bulan kalender.

Pencairan praktisi 48 jam setelah catatan penutup terkirim, kalau tidak ada komplain. Detail mesinnya di [03-sesi-dan-uang.md](./03-sesi-dan-uang.md).

## Sesi

Kanal pada katalog: chat, virtual, tatap muka. Yang bisa dijual pada launch adalah kombinasi yang punya harga dan tidak ditandai nonaktif.

Virtual memakai Google Meet yang dibuat akun Google Workspace Clarafin saat pembayaran lunas. Tautan hanya muncul di dalam sesi dan mati setelah sesi selesai. Platform tidak merekam Meet.

Chat adalah utas di dalam app. Durasi awal 3 hari, field di CMS. Bukan WhatsApp.

Tatap muka hanya di venue yang diterbitkan CMS. Praktisi tidak mengetik alamat sendiri. Tidak ada venue pada hari pertama, jadi tatap muka belum bisa dibooking.

Durasi awal virtual dan tatap muka 60 menit, keduanya field CMS.

Anti bocor:

- Profil tidak menampilkan nomor, email, atau akun sosial.
- Chat menolak pesan yang berisi nomor, email, rekening, atau tautan WhatsApp dan Telegram.
- Tidak ada status lunas tunai.
- Chat menjadi arsip baca-saja setelah jendelanya habis.
- Pelanggaran pertama peringatan, kedua potongan platform naik di dalam batas 10–35%, ketiga akun praktisi ditahan.
- Klien bisa melaporkan dari sesi.
- Praktisi menyetujui aturan ini sebelum diverifikasi.
- Membahas kebutuhan asuransi boleh untuk tier yang berwenang. Menagih premi atau mengirim tautan bayar produk tidak boleh.

Tidak ada antrean tunggu. Tidak ada booking hadiah. Couple mengikuti aturan di dokumen 03.

## AI dan tracker

Batas asisten, kuota, Gmail, izin catatan, dan hapus akun ada di [04-ai-dan-data-klien.md](./04-ai-dan-data-klien.md).

## Yang ditunda

- Aturan otomatis naik-turun persen berdasarkan rating dan jumlah sesi. Penimpaan manual sudah ada.
- Virtual account, e-wallet, kartu, dan perpanjangan Pro otomatis.
- Tatap muka, sampai ada venue aktif.
- Paket corporate, group/family, custom, dan high net worth.
- App praktisi terpisah, app admin terpisah, dan landing.
- Sync bank, skor kesehatan, voucher, dan ekspor sebagai syarat launch.
