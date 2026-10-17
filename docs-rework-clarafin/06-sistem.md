# Sistem

## Rumah

| Rumah | Punya |
| --- | --- |
| `apps/mobile` | Klien dan praktisi. Flutter, Riverpod, GoRouter. Data layar pindah dari notifier statis ke API |
| `apps/cms` | Web staf. Next.js, sesuai keputusan web yang sudah ada di repo |
| Supabase | Auth, Postgres, Storage untuk KTP, ijazah, foto nota, dan foto profil |
| `services/api` | Satu binary Go. Mesin sesi, uang, AI, Gmail, Meet |
| Xendit | QRIS dan pencairan. Dibungkus adapter |
| Google | Meet dari Workspace Clarafin. Gmail lewat OAuth klien. Login Google tidak wajib |
| Email dan push | Peristiwa di dokumen 04. Push lewat FCM |

Redis tidak menjadi sumber kebenaran. Hold slot disimpan di Postgres supaya undangan couple 24 jam tidak hilang saat proses Go mati.

## Tabel

Uang dalam `bigint` rupiah. Status dalam teks. Setiap tabel punya `id` UUID, `created_at`, dan `updated_at`.

| Tabel | Isi minimum |
| --- | --- |
| `profiles` | `user_id`, nama, tanggal lahir, email |
| `practitioner_applications` | KTP, berkas ijazah atau sertifikat, rekening, status `pending` / `verified` / `suspended` |
| `practitioners` | profil publik, tier, bahasa, bio, `platform_rate_bps` kosong atau 1000–3500 |
| `tiers`, `problem_tags`, `tier_tags` | katalog |
| `packages` | tier, peserta, kanal, durasi, harga dasar, harga maksimum, aktif |
| `practitioner_prices` | praktisi, paket, harga di dalam plafon |
| `venues` | nama, alamat, kota, aktif |
| `slots` | praktisi, mulai, selesai, status `open` / `held` / `booked` |
| `holds` | slot, pemesan, `expires_at` |
| `orders` | `session` atau `pro`, pembeli, harga, status |
| `payments` | provider, referensi, status. Tidak dibaca klien selain status order |
| `sessions` | paket, praktisi, pemesan, slot atau jendela chat, status, tautan Meet |
| `session_participants` | akun pada sesi. Couple punya dua baris |
| `closing_notes` | tiga bagian, `submitted_at`, terkunci saat payout lepas |
| `payouts` | bagian praktisi, `due_at`, status |
| `complaints` | sesi, teks klien, satu tanggapan, keputusan staf |
| `reviews` | sesi, nilai, teks, atau tersamar kalau akun dihapus |
| `consents` | sesi, pemberi, dompet, rentang tanggal, `expires_at`, status |
| `wallets`, `transactions` | catatan manual. Transaksi punya status `draft` atau `posted` |
| `categories` | kategori pengeluaran |
| `ai_actions` | pengguna, jenis, waktu, berhasil atau gagal |
| `gmail_connections` | token. Dihapus saat putus atau hapus akun |
| `pins` | tag, praktisi, urutan 1–3 |
| `settings` | batas umur, SLA chat, bendera metode bayar |
| `archive_records` | salinan profil, tracker, dan transkrip untuk retensi 5 tahun |
| `audit_events` | bayar, refund, buka arsip, ubah status praktisi, ubah persen |

## Siapa membaca apa

Klien membaca order, sesi, dan tracker miliknya. Praktisi membaca sesi yang ditugaskan kepadanya. Isi dompet hanya lewat izin `active` pada sesi itu. Praktisi tidak membaca `payments` selain status yang sudah diterjemahkan menjadi lunas atau belum. Staf membaca lewat service Go, bukan lewat kebijakan baris klien. Arsip tidak punya kebijakan baca untuk klien atau praktisi.

## Service Go

| Paket | Tugas |
| --- | --- |
| `catalog` | Daftar praktisi, saringan, sematan |
| `booking` | Hold, undang couple, pindah jadwal, batal |
| `payment` | QRIS, webhook idempotent, refund |
| `session` | Hadir, jendela chat, catatan, transisi status |
| `payout` | Jadwal 48 jam dan kirim ke rekening |
| `complaint` | Tahan payout dan terapkan keputusan staf |
| `checkup` | Kuota, panggilan model, tolak saran yang dilarang, usul praktisi |
| `gmail` | Sapuan resi, draf, buang isi mentah |
| `consent` | Buka dan cabut |
| `practice` | Slot, harga, catatan |
| `staff` | Persetujuan, katalog, komplain, arsip |
| `audit` | Tulis `audit_events` |

Webhook yang sama tidak boleh membuat dua order lunas atau dua Meet.

## Irisan

Setiap irisan berhenti kalau kondisi di kolom kanan benar di sandbox.

| Urutan | Kerja | Selesai kalau |
| --- | --- | --- |
| 1 | Auth, profil, tanggal lahir, katalog CMS terisi dari tabel harga di dokumen 02 | Daftar konsultan dibaca dari database, bukan dari file Dart |
| 2 | Lamaran praktisi dan persetujuan | Sebelum disetujui tidak ada UI praktisi. Sesudah disetujui, slot bisa dibuka |
| 3 | Hold, QRIS, webhook, sesi `confirmed`, Meet untuk virtual | Satu pembayaran mengubah slot menjadi `booked` dan muncul di kedua peran |
| 4 | Hadir, catatan, payout, refund pada kasus di dokumen 03 | Kasus keduanya tidak Hadir menahan 20% dan mengembalikan 80% |
| 5 | Cek: kuota, nota, Gmail, batas jawaban, urutan nama | Pertanyaan restrukturisasi tidak berisi langkah solusi |
| 6 | Dompet, transaksi, izin per sesi | Praktisi melihat dompet hanya saat izin aktif |
| 7 | Couple | Tidak ada tagihan sebelum undangan diterima |
| 8 | Komplain, ulasan, sematan, Pro | Komplain menahan payout. Pro menambah 400 aksi tanpa mengubah harga sesi |

Tracker goals, budget, tagihan, sync bank, voucher, skor, dan ekspor tidak menghalangi irisan ini.
