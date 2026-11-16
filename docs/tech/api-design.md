# API Design & Endpoint Specification — Clarafin (`/v1`)

| Field | Value |
| --- | --- |
| Project | **Clarafin** |
| Document Version | 4.0 (ERD v2.0 & AI Blueprint Aligned) |
| Status | Active Contract |
| Last Updated | 2026-11-17 |
| Base Path | `/v1` |
| Auth Header | `Authorization: Bearer <supabase_access_token>` |

---

## 1. Standar Kontrak REST API

1. **Format JSON & Penamaan:** Seluruh request dan response menggunakan `application/json` dengan penamaan field `snake_case` (kecuali endpoint chat AI streaming yang mengembalikan `text/event-stream` / SSE dengan payload JSON per event).
2. **Satuan Uang & Waktu:** Semua field uang bertipe integer (`IDR` bulat, contoh: `150000`), dan semua timestamp bertipe string ISO-8601 (`2026-11-01T10:00:00+07:00`).
3. **Envelope Standar:**
   - Sukses: `{"data": { ... }, "meta": {"request_id": "req_..."}}`
   - Error: `{"error": {"code": "QUOTA_EXCEEDED", "message": "Kuota aksi AI bulanan Anda telah habis.", "request_id": "req_..."}}`
4. **Idempotency & Rate Limit:**
   - Seluruh aksi AI (`chat`, `quick-add`, `ocr`) wajib mengirim `client_request_id` (UUID v4) untuk reservasi kuota atomik (`reserved -> success | failed`), sehingga kegagalan LLM tidak memotong kuota dan retry aman.
   - Mutasi transaksi (`POST /v1/transactions`) dan konfirmasi draf (`POST /v1/ai/drafts/:id/confirm`) wajib menyertakan `client_mutation_id` (UUID v4) untuk mencegah pencatatan ganda akibat *double-tap* atau timeout jaringan.
   - Endpoint `/v1/ai/*` dilindungi rate limiter Redis (`10 req/min` per `user_id`) untuk mencegah penyalahgunaan pada tier `Unlimited`.

---

## 2. Daftar Endpoint Kanonis (`/v1`)

### 2.1 Profil, Preferensi, & Koneksi Gmail
| Method | Path | Deskripsi |
| --- | --- | --- |
| `GET` | `/v1/me` | Mengambil profil pengguna (`users`, termasuk `birth_date` opsional tanpa syarat 18+, `selected_avatar_index`, `onboarding_completed`), preferensi lengkap (`user_preferences`), status verifikasi praktisi (`pending`/`verified`/`suspended`), status koneksi Gmail, dan sisa kuota AI. |
| `PATCH` | `/v1/me` | Memperbarui profil (`full_name`, `birth_date`, `phone`, `avatar_url`, `selected_avatar_index`, `monthly_budget_limit`, `onboarding_completed`) dan preferensi (`notifications_enabled`, `session_reminders_enabled`, `bill_reminders_enabled`, `promo_alerts_enabled`, `daily_reminder_enabled`, `daily_reminder_time_wib`, `tracking_history_source`, `tracker_focuses`, `advisory_focuses`, `biometric_enabled`, `preferred_currency`, `preferred_language`). |
| `DELETE` | `/v1/me` | Menghapus akun pengguna (ditolak dengan `409 CONFLICT` jika masih ada sesi aktif). Mengarsipkan riwayat pembayaran sesi ke `deleted_account_payment_archives` selama 5 tahun. |
| `POST` | `/v1/me/gmail/connect` | Menukar kode otorisasi Google OAuth (`gmail.readonly`), mengenkripsi refresh token (`AES-256-GCM`), dan memicu pemindaian mutasi 30 hari terakhir. |
| `POST` | `/v1/me/gmail/sync` | Memicu pemindaian ulang email mutasi/resi dari 30 hari terakhir menjadi `ai_drafts`. |
| `DELETE` | `/v1/me/gmail` | Memutuskan koneksi Gmail dan menghapus token terenkripsi. |

### 2.2 Pencatat Keuangan Personal (`Categories`, `Wallets`, `Transactions`, `Drafts`, `Budgets`, `Goals`, `Bills`, `Notifications`)
| Method | Path | Deskripsi |
| --- | --- | --- |
| `GET` | `/v1/categories` | Mengambil daftar kategori & sub-kategori kanonis (`TransactionCategories` enum) beserta alias lokal untuk sinkronisasi picker manual dan validasi AI. |
| `GET` | `/v1/wallets` | Daftar dompet & aset investasi aktif pengguna beserta total saldo dan persentase distribusi aset. |
| `POST` | `/v1/wallets` | Membuat dompet baru (`bank`, `ewallet`, `cash`, `deposit`, `mutual_fund`, `bond`, `stock`, `cex`, `dex`, `web3_wallet`, `crypto`, `investment`, `other`, `institution_code`, `return_percentage`, `is_volatile`). |
| `PATCH` | `/v1/wallets/:id` | Memperbarui nama/saldo/pengembalian investasi atau mengarsipkan dompet. |
| `GET` | `/v1/transactions` | Riwayat transaksi dengan filter `wallet_id`, `type`, `category`, `date_from`, `date_to`, dan pencarian kata kunci. |
| `POST` | `/v1/transactions` | Mencatat transaksi manual (`income`, `expense`, `transfer`, opsional `target_goal_id`) secara idempoten dengan `client_mutation_id` serta memperbarui saldo dompet/goal secara atomik. |
| `GET` | `/v1/ai/drafts` | Daftar draf transaksi (`pending_review`) dari AI maupun hasil pindai email Gmail. |
| `POST` | `/v1/ai/drafts/:id/confirm` | Mengonfirmasi draf (validasi kategori kanonis `TransactionCategories` + `client_mutation_id` anti double-tap) menjadi `transactions` final. |
| `POST` | `/v1/ai/drafts/:id/discard` | Menolak/membuang draf transaksi (`discarded`). |
| `GET` | `/v1/planning` | Mengambil ringkasan terpadu untuk layar `/budget` (sub-tab `goals`, `budgets`, dan `bills`). |
| `POST` | `/v1/budgets` | Menambah atau memperbarui batas anggaran kategori kanonis bulanan (`UNIQUE(user_id, category, month_year)`). |
| `POST` | `/v1/goals` | Membuat target tabungan baru beserta prioritas (`urgent`, `needs`, `wants`) dan `linked_wallet_id`. |
| `PATCH` | `/v1/goals/:id` | Memperbarui target tabungan atau mengubah status goal. |
| `POST` | `/v1/goals/:id/contributions` | Menambah/memperbarui alokasi dana dari dompet spesifik ke goal (`goal_contributions`) secara atomik. |
| `POST` | `/v1/bills` | Menambahkan pengingat tagihan baru (`due_date` opsional). |
| `PATCH` | `/v1/bills/:id` | Menandai tagihan lunas (`is_paid`) atau mengubah detail tagihan. |
| `GET` | `/v1/notifications` | Mengambil daftar notifikasi pengguna. |
| `POST` | `/v1/notifications/read-all` | Menandai seluruh notifikasi sebagai telah dibaca. |

### 2.3 Asisten AI Berkuota, Ephemeral Chat, & Langganan Clarafin Pro / Unlimited
| Method | Path | Deskripsi |
| --- | --- | --- |
| `GET` | `/v1/ai/quota` | Mengambil sisa kuota aksi AI bulan ini berdasarkan bucket (`free` 40/bulan, `pro` 400/30 hari, `unlimited` `-1` tanpa batas + fair-use rate limit, dan `bonus` konsultasi) serta tanggal berakhir paket. |
| `POST` | `/v1/ai/chat` | Mengirim pesan ke Clarafin AI (**SSE `text/event-stream`**). Wajib menyertakan `client_request_id` (reservasi kuota atomik), `surface_mode` (`quick_sheet` \| `full_screen`), dan `session_history` **Zero-Trust** (maks 8–10 giliran terakhir, hanya `{role: "user" \| "model", text}` ≤ 1.000 karakter/pesan; server menolak role `system`/`tool`). Menjalankan **Strict Two-Pass Gemini** (Pass 1 tool JWT-locked + sub-call `google_search`; Pass 2 structured JSON + mapper kategori kanonis) dengan rate limit Redis `10 req/min/user_id`. Untuk topik perencanaan/keputusan kompleks, AI tetap memberi ***helpful hint* netral yang tidak dibatasi secara kaku dan tidak berlebihan**, lalu menyertakan *soft boundary* dan `recommended_packages` / `recommended_practitioners` (1–3 praktisi) untuk handoff ke `BookingFlowScreen`. **Tidak ada endpoint histori chat server (`GET/DELETE /v1/ai/sessions`)**; aksi **`New Chat`** membatalkan stream SSE aktif dan mereset state lokal di klien. |
| `POST` | `/v1/ai/quick-add` | Mengekstrak teks atau transkrip suara menjadi `ai_drafts` (`pending_review`) memakai kategori kanonis (`TransactionCategories`) dan `client_request_id`. Gagal parsing tidak memotong kuota. |
| `POST` | `/v1/ai/ocr` | Mengekstrak foto struk belanja menjadi `ai_drafts` (`pending_review`) memakai kategori kanonis (`TransactionCategories`) dan `client_request_id`. Gagal parsing tidak memotong kuota. |
| `POST` | `/v1/pro/subscribe` | Membuat record `orders` & tagihan QRIS Xendit untuk paket **Clarafin Pro (`pro_monthly`: Rp 49.000 / 30 hari, 400 aksi)** atau **Clarafin Unlimited (`unlimited_monthly`: Rp 99.000 / bulan atau `unlimited_yearly`)** dengan dukungan `voucher_code`. |

### 2.4 Katalog Paket, Praktisi, Match Expert, Orders, & Siklus Hidup Sesi
| Method | Path | Deskripsi |
| --- | --- | --- |
| `GET` | `/v1/catalog-packages` | Mengambil daftar master paket layanan resmi Clarafin (`catalog_packages`) beserta rentang tarif dan durasi. |
| `GET` | `/v1/practitioners` | Daftar praktisi terverifikasi (`status = 'verified'`) dengan filter spesialisasi, kota, tingkat layanan (`basic`, `medium`, `premium`), dan kanal. |
| `GET` | `/v1/practitioners/:id` | Detail profil praktisi, paket aktif (`practitioner_packages`), jadwal tersedia (`practitioner_availability`), dan ulasan klien. |
| `GET` | `/v1/venues` | Daftar venue Tatap Muka aktif per kota. |
| `GET` | `/v1/vouchers` | Daftar voucher promo aktif yang berlaku untuk layanan konsultasi atau paket AI SaaS. |
| `POST` | `/v1/match-expert/submissions` | Menyimpan jawaban kuesioner Match Expert (`match_expert_submissions`) dan mengembalikan peringkat top praktisi terverifikasi. |
| `GET` | `/v1/orders/:id` | Mengambil status pembayaran order checkout (`consultation_session`, `saas_pro`, `saas_unlimited`) dan data instruksi QRIS. |
| `POST` | `/v1/sessions` | Membuat order + hold slot (`booking_slot_holds` 15m) + sesi baru (Solo -> `waiting_payment` 15m + QRIS Xendit; Couple -> `waiting_partner` 24h) dengan dukungan `session_count` (`1\|2\|3\|8`), `online_method` (`call\|video\|chat`), `voucher_code`, `intake_topics`, `pre_consult_expectations`, persetujuan tunggal (`terms_and_data_consent_accepted`), dan `wallet_ids` (`consents`). |
| `POST` | `/v1/sessions/:id/partner-accept` | Khusus pasangan pada sesi Couple: menerima undangan, memilih `wallet_ids` pasangan, dan memicu pembuatan QRIS 15 menit. |
| `POST` | `/v1/sessions/:id/partner-decline` | Menolak undangan sesi Couple (`cancelled`) dan melepas `booking_slot_holds`. |
| `POST` | `/v1/sessions/:id/attend` | Klien menekan tombol **`Hadir`** pada 15 menit pertama sesi (`attendance_confirmed_at`). |
| `POST` | `/v1/sessions/:id/reschedule` | Mengajukan penjadwalan ulang (maksimal 1x, minimal 24 jam sebelum sesi mulai). |
| `POST` | `/v1/sessions/:id/cancel` | Membatalkan sesi sesuai aturan refund (>=24h 100%, <24h 50%, oleh praktisi 100%) dan melepas `booking_slot_holds`. |
| `GET` | `/v1/sessions/:id/client-summary` | Khusus Praktisi sesi terkait: melihat ringkasan dompet, anggaran, dan target yang diizinkan di `consents` selama sesi aktif. |
| `POST` | `/v1/sessions/:id/consent/revoke` | Klien mencabut izin akses dompet (`consents.status = 'revoked'`) kapan saja. |
| `POST` | `/v1/sessions/:id/notes` | Khusus Praktisi: mengirim **Catatan Penutup 3 Bagian** (`core_issue`, `action_steps`, `dont_rule`) dalam 24 jam setelah sesi berakhir. Mengubah status menjadi `completed` dan mengatur `payout_ready_at = NOW() + 48 jam`. |
| `POST` | `/v1/sessions/:id/complaint` | Klien mengajukan keluhan sebelum dana cair (`status = 'disputed'`). |
| `POST` | `/v1/sessions/:id/review` | Klien memberi rating 1–5 dan ulasan setelah sesi `completed`. |
| `POST` | `/v1/practitioners/apply` | Mengajukan diri sebagai praktisi dari halaman Profil pengguna (`status = 'pending'`). |

### 2.5 Webhook & Endpoint Internal Staff CMS (`/v1/cms/*`)
| Method | Path | Deskripsi |
| --- | --- | --- |
| `POST` | `/v1/webhooks/xendit` | Menerima callback pembayaran Xendit (`payments` -> `orders`) untuk sesi konsultasi (mengonversi `booking_slot_holds` menjadi `booked`), Clarafin Pro, maupun Clarafin Unlimited secara idempoten. |
| `PATCH` | `/v1/cms/practitioners/:id/verify` | Staff menyetujui (`verified`) atau membekukan (`suspended`) praktisi serta mengatur `platform_cut_pct` (`10%–35%`). |
| `PUT` | `/v1/cms/problem-tags/:id/pins` | Staff menetapkan pin 1–3 praktisi prioritas (`staff_practitioner_pins`) untuk setiap `problem_tags` yang dipakai AI routing. |
| `POST` | `/v1/cms/catalog-packages` | Staff mengelola master paket layanan `catalog_packages`. |
| `POST` | `/v1/cms/venues` | Staff menambah atau memperbarui lokasi `venues` Tatap Muka. |
| `POST` | `/v1/cms/complaints/:id/resolve` | Staff menyelesaikan sengketa sesi (`resolved_practitioner`, `resolved_full_refund`, `resolved_partial_refund`). |
| `POST` | `/v1/cms/payouts/:id/mark-paid` | Staff menandai pencairan dana praktisi telah ditransfer beserta bukti transfer. |
