# Peta layar

Aplikasi klien dan praktisi adalah `apps/mobile` yang sudah ada. CMS adalah web baru untuk staf. Layar di bawah ini yang dipakai launch. Layar Flutter yang tidak disebut boleh tetap di repo, dan bukan pintu pertama.

## Klien

Nav dari kiri ke kanan: Konsultan, Cek, Sesi di tengah, Uang, Akun.

| Layar | Rute | Dari kode yang ada | Kerja |
| --- | --- | --- | --- |
| Daftar dan masuk | `/login`, `/register` | `auth_login_screen`, `auth_register_screen` | Daftar menyimpan nama dan tanggal lahir. Masuk bertahan setelah app ditutup |
| Daftar konsultan | `/consult`, juga tujuan setelah masuk | `consult_list_screen` | Ini beranda. Bukan saldo. Saring tier, tag, kanal, bahasa, harga |
| Detail praktisi | `/consult/:id` | `consult_detail_screen` | Harga per paket aktif, slot, bahasa. Tanpa nomor dan email |
| Booking | `/booking/:id/...` | `booking_flow_screen` | Satu kanal yang dipilih. Couple meminta email pasangan sebelum bayar |
| Bayar | `/booking/:id/payment` | `booking_payment_screen` | Hanya QRIS yang bisa diketuk. Voucher tetap tidak dipakai |
| Sesi | `/session` | `branch_session_screen` | Akan datang, berjalan, menunggu catatan, selesai |
| Detail sesi | `/session/:id` | perlu layar detail | Hadir, tautan Meet, utas chat, izin catatan, batal, pindah jadwal, komplain, ulasan, baca catatan penutup |
| Cek | `/cek` | `ai_chat_screen` dijadikan ulang | Bukan chat kosong tanpa kuota. Alat catat, nota, Gmail, dan analisa ada di sini |
| Konfirmasi draf | dari Cek | `ai_draft_review_screen` | Draf nota, teks, atau Gmail. Konfirmasi menulis transaksi |
| Uang | `/uang` | `wallet_screen` dan riwayat transaksi | Dompet, transaksi, ringkasan bulan. Kosong tetap sah |
| Notifikasi | `/notifications` | `notification_screen` | Daftar peristiwa yang sama dengan email dan push |
| Akun | `/profile` | `profile_screen` | Pro, sambungan Gmail, status lamaran praktisi, hapus akun |
| Undang couple | dari booking | baru | Terima atau tolak undangan |

Match expert yang sekarang menjadi langkah akhir Cek, bukan produk terpisah. Onboarding yang memaksa membuat dompet tidak dipakai sebagai pintu masuk.

## Praktisi

Bagian ini tidak terlihat sebelum status `verified`.

| Layar | Isi |
| --- | --- |
| Antrean | Sesi lunas. Brief hanya untuk sesi yang izinnya aktif |
| Slot | Buka dan tutup jam `open` |
| Detail sesi | Hadir, utas, Meet, formulir catatan penutup |
| Paket | Pilih paket aktif dan pasang harga di dalam plafon |
| Profil publik | Bio, bahasa, foto. Tanpa kontak pribadi |
| Rekening | Nomor rekening. Perubahan menunggu staf |
| Lamaran | Terlihat dari akun klien selama `pending`: KTP, ijazah atau sertifikat, rekening |

## Staf

Web CMS, bukan tab di app.

| Layar | Isi |
| --- | --- |
| Praktisi | Antrian `pending`, setujui, tunda, ubah persen 10–35% |
| Katalog | Tier, tag, paket, dasar, maksimum, durasi, aktif |
| Venue | Nama, alamat, kota, aktif |
| Kategori | Kategori pengeluaran |
| Batas umur | Empat angka, kosong sampai diisi |
| Sematan | Per tag, maksimal 3 |
| Komplain | Satu tanggapan praktisi, lalu refund penuh, sebagian, atau lepas |
| Pembayaran | Order, webhook, payout, rekening yang menunggu |
| Metode bayar | QRIS hidup. Dua metode lain tetap mati sampai siap |
| Laporan bocor | Peringatan, naikkan potongan, atau `suspended` |

## Yang tidak masuk pintu launch

`voucher_screen`, `financial_health_screen`, `export_data_screen`, `goals_screen`, `bills_screen`, tiga layar booking lama, dan `old_transaction_entry_screen`. Home saldo yang sekarang diganti daftar konsultan.
