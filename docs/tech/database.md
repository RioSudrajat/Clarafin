# Database Strategy & DDL Specification — Clarafin

| Field | Value |
| --- | --- |
| Project | **Clarafin** |
| Document Version | 4.0 (ERD v2.0 — 36 Canonical Tables & AI Blueprint Aligned) |
| Status | Active Specification |
| Last Updated | 2026-11-17 |
| Reference Diagram | [Entity Relationship Diagram (`erd.md`)](./erd.md) |

---

## 1. Prinsip Desain Database

1. **PostgreSQL + Supabase Managed Platform:** Memanfaatkan autentikasi (`auth.users`), Row-Level Security (RLS), dan transaksi ACID PostgreSQL.
2. **Satuan Uang Bulat (`BIGINT` IDR):** Seluruh kolom nominal uang disimpan dalam satuan Rupiah utuh (`BIGINT`) tanpa pecahan desimal (`FLOAT`/`REAL` dilarang untuk nominal uang).
3. **Zona Waktu Standar (`TIMESTAMPTZ`):** Seluruh kolom waktu menggunakan `TIMESTAMPTZ` (UTC di penyimpanan), sementara pemotongan batas tanggal bisnis (seperti reset kuota AI tanggal 1 pukul 00:00 dan jadwal ketersediaan praktisi) dievaluasi dalam zona waktu **WIB (`Asia/Jakarta`)**.
4. **Enkripsi Token Sensitif:** Refresh token OAuth Gmail disimpan dalam kolom `BYTEA` (`encrypted_refresh_token`) yang dienkripsi di level aplikasi Go menggunakan **AES-256-GCM**.
5. **Kepatuhan Penghapusan Akun (Retensi 5 Tahun):** Saat pengguna menghapus akun, data personal dan catatan keuangannya dihapus (`CASCADE`), sedangkan ringkasan nilai transaksi pembayaran sesi diarsipkan secara anonim di `deleted_account_payment_archives` selama 5 tahun.
6. **Ephemeral AI Chat, Reservasi Kuota Atomik, & Idempotensi Mutasi:** Tidak ada tabel `ai_chat_sessions` atau `ai_chat_messages` di server—riwayat obrolan Clarafin AI bersifat *ephemeral* di memori klien dan tombol `New Chat` langsung mereset sesi tanpa jejak DB. Setiap panggilan AI menggunakan `request_id` (`client_request_id`) pada `ai_usage_ledger` dengan transisi status `reserved -> success | failed` (kuota hanya terpotong saat `success`), dan mutasi dari draf/transaksi menggunakan `client_mutation_id` parsial unik agar *double-tap* atau *retry* tidak menghasilkan pencatatan ganda.

---

## 2. Core SQL DDL (36 Tabel Kanonis)

> **Catatan Urutan Dependensi FK:** Tabel `goals` didefinisikan sebelum `transactions` (`target_goal_id`), `vouchers` sebelum `orders`, serta `orders` dan `sessions` sebelum `booking_slot_holds` dan `pro_subscriptions`.

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. USERS (Profil Pengguna Ekstensi auth.users)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  birth_date DATE, -- Bersifat opsional saat signup; tidak ada pemblokiran usia 18+
  phone TEXT,
  avatar_url TEXT,
  selected_avatar_index INTEGER CHECK (selected_avatar_index BETWEEN 1 AND 6),
  monthly_budget_limit BIGINT NOT NULL DEFAULT 5000000 CHECK (monthly_budget_limit >= 0),
  onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- 2. USER_PREFERENCES (Preferensi Notifikasi, Onboarding Focus, & Keamanan)
CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  session_reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  bill_reminders_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  promo_alerts_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  daily_reminder_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  daily_reminder_time_wib TIME NOT NULL DEFAULT '20:00:00',
  tracking_history_source TEXT NOT NULL DEFAULT 'fresh_start' CHECK (tracking_history_source IN ('fresh_start', 'other_app', 'spreadsheet')),
  tracker_focuses TEXT[] NOT NULL DEFAULT '{}',
  advisory_focuses TEXT[] NOT NULL DEFAULT '{basic}',
  biometric_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  pin_hash TEXT,
  preferred_currency TEXT NOT NULL DEFAULT 'IDR' CHECK (preferred_currency IN ('IDR', 'USD', 'SGD', 'MYR', 'EUR', 'JPY')),
  preferred_language TEXT NOT NULL DEFAULT 'Bahasa Indonesia' CHECK (preferred_language IN ('Bahasa Indonesia', 'English')),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. CATEGORIES (Master Katalog Kategori Kanonis TransactionCategories & Sub-Kategori)
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  parent_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  group_name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  emoji TEXT NOT NULL,
  icon_key TEXT NOT NULL,
  color_hex TEXT NOT NULL,
  bg_color_hex TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. WALLETS (Dompet Kas, Bank, E-Wallet, Deposit, & Aset Investasi)
CREATE TABLE wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN (
    'bank', 'ewallet', 'cash', 'deposit', 'mutual_fund', 'bond',
    'stock', 'cex', 'dex', 'web3_wallet', 'crypto', 'investment', 'other'
  )),
  institution_code TEXT,
  account_number_masked TEXT,
  balance BIGINT NOT NULL DEFAULT 0,
  is_auto_sync BOOLEAN NOT NULL DEFAULT FALSE,
  custom_color_hex TEXT,
  return_percentage REAL,
  dividend_drop_date TIMESTAMPTZ,
  is_volatile BOOLEAN NOT NULL DEFAULT FALSE,
  has_claimed_dividend BOOLEAN NOT NULL DEFAULT FALSE,
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. GOALS (Target Tabungan / Impian Keuangan)
CREATE TABLE goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  linked_wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  target_amount BIGINT NOT NULL CHECK (target_amount > 0),
  saved_amount BIGINT NOT NULL DEFAULT 0 CHECK (saved_amount >= 0),
  target_date DATE,
  priority TEXT NOT NULL DEFAULT 'wants' CHECK (priority IN ('urgent', 'needs', 'wants')),
  source_asset_label TEXT,
  icon_key TEXT,
  tag_color_hex TEXT,
  tag_text_color_hex TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'archived')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. GOAL_CONTRIBUTIONS (Alokasi Kontribusi Target per Dompet)
CREATE TABLE goal_contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT,
  contributed_amount BIGINT NOT NULL DEFAULT 0 CHECK (contributed_amount >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (goal_id, wallet_id)
);

-- 7. TRANSACTIONS (Catatan Keuangan Pemasukan, Pengeluaran, & Transfer Final)
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE RESTRICT,
  destination_wallet_id UUID REFERENCES wallets(id) ON DELETE RESTRICT,
  target_goal_id UUID REFERENCES goals(id) ON DELETE SET NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  category TEXT NOT NULL,
  amount BIGINT NOT NULL CHECK (amount > 0),
  title TEXT NOT NULL,
  note TEXT,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  source TEXT NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'ai_text', 'ai_voice', 'ocr', 'gmail')),
  client_mutation_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_transactions_client_mutation
  ON transactions (user_id, client_mutation_id)
  WHERE client_mutation_id IS NOT NULL;

-- 8. AI_DRAFTS (Staging Draf AI Quick-Add, OCR, Voice, & Gmail Scanner)
CREATE TABLE ai_drafts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL,
  destination_wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL,
  batch_id UUID,
  source TEXT NOT NULL CHECK (source IN ('ai_text', 'ai_voice', 'ocr', 'gmail')),
  external_ref_id TEXT,
  client_mutation_id TEXT,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  category TEXT NOT NULL,
  amount BIGINT NOT NULL CHECK (amount > 0),
  title TEXT NOT NULL,
  merchant_or_note TEXT NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  confidence_score REAL NOT NULL DEFAULT 0.9 CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0),
  status TEXT NOT NULL DEFAULT 'pending_review' CHECK (status IN ('pending_review', 'confirmed', 'discarded')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, source, external_ref_id)
);

CREATE UNIQUE INDEX uq_ai_drafts_client_mutation
  ON ai_drafts (user_id, client_mutation_id)
  WHERE client_mutation_id IS NOT NULL;

-- 9. BUDGETS (Batas Anggaran Kategori Bulanan)
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  category TEXT NOT NULL,
  month_year TEXT NOT NULL CHECK (month_year ~ '^[0-9]{4}-[0-9]{2}$'),
  limit_amount BIGINT NOT NULL CHECK (limit_amount > 0),
  icon_key TEXT,
  color_hex TEXT,
  bg_color_hex TEXT,
  alert_80_sent BOOLEAN NOT NULL DEFAULT FALSE,
  alert_100_sent BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, category, month_year)
);

-- 10. BILLS (Pengingat Tagihan Rutin / Sekali Bayar)
CREATE TABLE bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  category TEXT,
  amount BIGINT NOT NULL CHECK (amount > 0),
  due_date DATE,
  frequency TEXT NOT NULL DEFAULT 'monthly' CHECK (frequency IN ('once', 'weekly', 'monthly', 'yearly')),
  is_paid BOOLEAN NOT NULL DEFAULT FALSE,
  auto_pay BOOLEAN NOT NULL DEFAULT FALSE,
  icon_key TEXT,
  icon_color_hex TEXT,
  icon_bg_color_hex TEXT,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. NOTIFICATIONS (Kotak Masuk Notifikasi In-App)
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('session', 'transaction', 'budget', 'bill', 'promo', 'system')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  action_route TEXT,
  action_label TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. PRACTITIONER_PROFILES (Profil & Verifikasi Praktisi Terkurasi)
CREATE TABLE practitioner_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  title_headline TEXT NOT NULL,
  bio TEXT NOT NULL,
  city TEXT NOT NULL,
  practitioner_tier TEXT NOT NULL DEFAULT 'basic' CHECK (practitioner_tier IN ('basic', 'medium', 'premium')),
  clients_handled_count INTEGER NOT NULL DEFAULT 0 CHECK (clients_handled_count >= 0),
  certifications TEXT[] NOT NULL DEFAULT '{}',
  certificate_file_urls TEXT[] NOT NULL DEFAULT '{}',
  ktp_file_url TEXT NOT NULL,
  specializations TEXT[] NOT NULL DEFAULT '{}',
  languages TEXT[] NOT NULL DEFAULT '{Indonesia}',
  supported_methods TEXT[] NOT NULL DEFAULT '{online}',
  gender TEXT,
  birth_year INTEGER,
  consulting_style TEXT,
  years_of_experience INTEGER NOT NULL DEFAULT 1 CHECK (years_of_experience >= 0),
  is_fully_booked BOOLEAN NOT NULL DEFAULT FALSE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'suspended')),
  platform_cut_pct INTEGER NOT NULL DEFAULT 20 CHECK (platform_cut_pct BETWEEN 10 AND 35),
  violation_count INTEGER NOT NULL DEFAULT 0 CHECK (violation_count >= 0),
  bank_name TEXT,
  bank_account_number TEXT,
  bank_account_holder TEXT,
  pending_bank_change_json JSONB,
  rating_avg REAL NOT NULL DEFAULT 0.0,
  review_count INTEGER NOT NULL DEFAULT 0,
  total_sessions_completed INTEGER NOT NULL DEFAULT 0,
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 13. CATALOG_PACKAGES (Master Katalog Paket Layanan Resmi Clarafin)
CREATE TABLE catalog_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  service_category TEXT NOT NULL CHECK (service_category IN ('individual', 'couple', 'umkm', 'corporate', 'financial_checkup')),
  category_tag TEXT NOT NULL,
  tier TEXT NOT NULL CHECK (tier IN ('basic', 'medium', 'premium', 'pre_marriage', 'marriage')),
  participant_type TEXT NOT NULL CHECK (participant_type IN ('solo', 'couple', 'group_family', 'corporate')),
  package_title TEXT NOT NULL,
  short_desc TEXT NOT NULL,
  full_desc TEXT NOT NULL,
  features TEXT[] NOT NULL DEFAULT '{}',
  online_duration_minutes INTEGER NOT NULL DEFAULT 60 CHECK (online_duration_minutes > 0),
  offline_duration_minutes INTEGER NOT NULL DEFAULT 90 CHECK (offline_duration_minutes > 0),
  base_online_price_idr BIGINT NOT NULL CHECK (base_online_price_idr > 0),
  max_online_price_idr BIGINT NOT NULL CHECK (max_online_price_idr >= base_online_price_idr),
  base_offline_price_idr BIGINT NOT NULL CHECK (base_offline_price_idr > 0),
  max_offline_price_idr BIGINT NOT NULL CHECK (max_offline_price_idr >= base_offline_price_idr),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 14. PRACTITIONER_PACKAGES (Paket & Tarif Resmi yang Diaktifkan per Praktisi)
CREATE TABLE practitioner_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  practitioner_id UUID NOT NULL REFERENCES practitioner_profiles(user_id) ON DELETE CASCADE,
  catalog_package_id UUID REFERENCES catalog_packages(id) ON DELETE SET NULL,
  service_category TEXT NOT NULL CHECK (service_category IN ('individual', 'couple', 'umkm', 'corporate', 'financial_checkup')),
  category_tag TEXT NOT NULL,
  tier TEXT NOT NULL CHECK (tier IN ('basic', 'medium', 'premium', 'pre_marriage', 'marriage')),
  package_title TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 60 CHECK (duration_minutes > 0),
  online_price_idr BIGINT CHECK (online_price_idr IS NULL OR online_price_idr > 0),
  offline_price_idr BIGINT CHECK (offline_price_idr IS NULL OR offline_price_idr > 0),
  is_online_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_offline_active BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (practitioner_id, catalog_package_id)
);

-- 15. PROBLEM_TAGS (Tag Masalah Kanonis untuk AI Routing & Filter Pencarian)
CREATE TABLE problem_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT NOT NULL UNIQUE,
  label TEXT NOT NULL,
  min_tier TEXT NOT NULL CHECK (min_tier IN ('basic', 'medium', 'premium')),
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 16. STAFF_PRACTITIONER_PINS (Pin 1-3 Praktisi Prioritas Kurasi Staff per Tag)
CREATE TABLE staff_practitioner_pins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  problem_tag_id UUID NOT NULL REFERENCES problem_tags(id) ON DELETE CASCADE,
  practitioner_id UUID NOT NULL REFERENCES practitioner_profiles(user_id) ON DELETE CASCADE,
  priority_order INTEGER NOT NULL CHECK (priority_order BETWEEN 1 AND 3),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (problem_tag_id, priority_order),
  UNIQUE (problem_tag_id, practitioner_id)
);

-- 17. PRACTITIONER_AVAILABILITY (Jadwal Slot Mingguan Praktisi - WIB)
CREATE TABLE practitioner_availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  practitioner_id UUID NOT NULL REFERENCES practitioner_profiles(user_id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time_wib TIME NOT NULL,
  end_time_wib TIME NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  CHECK (end_time_wib > start_time_wib)
);

-- 18. VENUES (Lokasi Tatap Muka Resmi yang Dikelola Staff CMS)
CREATE TABLE venues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  address TEXT NOT NULL,
  maps_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 19. VOUCHERS (Master Promo & Diskon Pembayaran)
CREATE TABLE vouchers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('all', 'counseling', 'investment')),
  discount_type TEXT NOT NULL CHECK (discount_type IN ('fixed_idr', 'percentage')),
  discount_value BIGINT NOT NULL CHECK (discount_value > 0),
  max_discount_idr BIGINT,
  min_transaction_idr BIGINT NOT NULL DEFAULT 0 CHECK (min_transaction_idr >= 0),
  valid_until TIMESTAMPTZ NOT NULL,
  usage_limit INTEGER,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 20. MATCH_EXPERT_SUBMISSIONS (Riwayat Kuesioner Match Expert & Top Skor Praktisi)
CREATE TABLE match_expert_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  answers_json JSONB NOT NULL,
  top_practitioner_ids UUID[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 21. ORDERS (Header Transaksi Checkout Sesi Konsultasi, Pro, & Unlimited)
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_code TEXT UNIQUE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  order_type TEXT NOT NULL CHECK (order_type IN ('consultation_session', 'saas_pro', 'saas_unlimited')),
  voucher_id UUID REFERENCES vouchers(id) ON DELETE SET NULL,
  voucher_code TEXT,
  subtotal_idr BIGINT NOT NULL CHECK (subtotal_idr >= 0),
  bundle_discount_idr BIGINT NOT NULL DEFAULT 0 CHECK (bundle_discount_idr >= 0),
  platform_fee_idr BIGINT NOT NULL DEFAULT 0 CHECK (platform_fee_idr >= 0),
  voucher_discount_idr BIGINT NOT NULL DEFAULT 0 CHECK (voucher_discount_idr >= 0),
  total_paid_idr BIGINT NOT NULL CHECK (total_paid_idr >= 0),
  payment_method TEXT NOT NULL DEFAULT 'qris' CHECK (payment_method IN ('qris', 'va', 'ewallet')),
  status TEXT NOT NULL DEFAULT 'waiting_payment' CHECK (status IN ('waiting_partner', 'waiting_payment', 'paid', 'expired', 'cancelled', 'refunded')),
  expires_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 22. PAYMENTS (Transaksi Pembayaran Xendit QRIS / VA / E-Wallet & Webhook Log)
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  provider TEXT NOT NULL DEFAULT 'xendit',
  provider_reference_id TEXT NOT NULL UNIQUE,
  qris_string TEXT,
  amount_idr BIGINT NOT NULL CHECK (amount_idr >= 0),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'expired', 'failed')),
  raw_webhook_payload JSONB,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 23. SESSIONS (Siklus Hidup Sesi Konsultasi Solo, Couple, Multi-Sesi, UMKM, Corporate)
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  booking_code TEXT,
  client_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  partner_user_id UUID REFERENCES users(id) ON DELETE RESTRICT,
  practitioner_id UUID NOT NULL REFERENCES practitioner_profiles(user_id) ON DELETE RESTRICT,
  package_id UUID REFERENCES practitioner_packages(id) ON DELETE SET NULL,
  service_category TEXT NOT NULL CHECK (service_category IN ('individual', 'couple', 'umkm', 'corporate', 'financial_checkup')),
  tier TEXT NOT NULL CHECK (tier IN ('basic', 'medium', 'premium', 'pre_marriage', 'marriage')),
  package_title TEXT NOT NULL,
  delivery_mode TEXT NOT NULL CHECK (delivery_mode IN ('online', 'offline')),
  online_method TEXT CHECK (online_method IN ('call', 'video', 'chat')),
  session_index INTEGER NOT NULL DEFAULT 1 CHECK (session_index >= 1),
  session_count INTEGER NOT NULL DEFAULT 1 CHECK (session_count IN (1, 2, 3, 8)),
  venue_id UUID REFERENCES venues(id) ON DELETE SET NULL,
  scheduled_start_at TIMESTAMPTZ NOT NULL,
  scheduled_end_at TIMESTAMPTZ NOT NULL,
  subtotal_price_idr BIGINT NOT NULL CHECK (subtotal_price_idr >= 0),
  platform_fee_idr BIGINT NOT NULL DEFAULT 15000 CHECK (platform_fee_idr >= 0),
  voucher_code TEXT,
  discount_amount_idr BIGINT NOT NULL DEFAULT 0 CHECK (discount_amount_idr >= 0),
  price_paid BIGINT NOT NULL CHECK (price_paid >= 0),
  platform_cut_pct INTEGER NOT NULL CHECK (platform_cut_pct BETWEEN 10 AND 35),
  terms_and_data_consent_accepted BOOLEAN NOT NULL DEFAULT FALSE,
  status TEXT NOT NULL CHECK (status IN (
    'waiting_partner', 'waiting_payment', 'scheduled', 'ongoing',
    'awaiting_notes', 'completed', 'disputed', 'cancelled',
    'no_show_client', 'no_show_practitioner'
  )),
  xendit_invoice_id TEXT,
  xendit_qris_string TEXT,
  payment_expires_at TIMESTAMPTZ,
  partner_invite_expires_at TIMESTAMPTZ,
  partner_accepted_at TIMESTAMPTZ,
  meet_url TEXT,
  chat_window_expires_at TIMESTAMPTZ,
  practitioner_first_reply_at TIMESTAMPTZ,
  intake_topics TEXT[] NOT NULL DEFAULT '{}',
  pre_consult_note TEXT,
  pre_consult_expectations TEXT,
  attachment_urls TEXT[] NOT NULL DEFAULT '{}',
  attendance_confirmed_at TIMESTAMPTZ,
  practitioner_attended_at TIMESTAMPTZ,
  reschedule_count INTEGER NOT NULL DEFAULT 0 CHECK (reschedule_count <= 1),
  refund_amount_idr BIGINT NOT NULL DEFAULT 0 CHECK (refund_amount_idr >= 0),
  completed_at TIMESTAMPTZ,
  payout_ready_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (scheduled_end_at > scheduled_start_at)
);

-- 24. BOOKING_SLOT_HOLDS (Anti Double-Booking Saat Hold Slot Pembayaran 15 Menit)
CREATE TABLE booking_slot_holds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  practitioner_id UUID NOT NULL REFERENCES practitioner_profiles(user_id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  slot_start_at TIMESTAMPTZ NOT NULL,
  slot_end_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'held' CHECK (status IN ('held', 'booked', 'released')),
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (slot_end_at > slot_start_at)
);

CREATE UNIQUE INDEX uq_active_practitioner_slot
  ON booking_slot_holds (practitioner_id, slot_start_at)
  WHERE status IN ('held', 'booked');

-- 25. CONSENTS (Izin Akses Dompet Per-Sesi & Per-User Termasuk Pasangan)
CREATE TABLE consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  wallet_ids UUID[] NOT NULL DEFAULT '{}',
  date_from DATE NOT NULL,
  date_to DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked', 'expired')),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  UNIQUE (session_id, user_id)
);

-- 26. SESSION_MESSAGES (Ruang Chat & Attachment Sesi Konsultasi)
CREATE TABLE session_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  sender_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  attachment_url TEXT,
  is_flagged_leak BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 27. SESSION_NOTES (Catatan Penutup 3 Bagian Wajib dari Praktisi)
CREATE TABLE session_notes (
  session_id UUID PRIMARY KEY REFERENCES sessions(id) ON DELETE CASCADE,
  core_issue TEXT NOT NULL,
  action_steps TEXT NOT NULL,
  dont_rule TEXT NOT NULL,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  locked_at TIMESTAMPTZ
);

-- 28. SESSION_REVIEWS (Rating & Ulasan Pasca-Sesi dari Klien)
CREATE TABLE session_reviews (
  session_id UUID PRIMARY KEY REFERENCES sessions(id) ON DELETE CASCADE,
  reviewer_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  is_anonymized BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 29. SESSION_COMPLAINTS (Pengajuan Sengketa Klien Sebelum Dana Cair)
CREATE TABLE session_complaints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL UNIQUE REFERENCES sessions(id) ON DELETE CASCADE,
  reporter_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  reason TEXT NOT NULL,
  evidence_url TEXT,
  practitioner_response TEXT,
  refund_amount_idr BIGINT CHECK (refund_amount_idr IS NULL OR refund_amount_idr >= 0),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved_practitioner', 'resolved_full_refund', 'resolved_partial_refund')),
  staff_resolution_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- 30. PAYOUTS (Escrow & Pencairan Honor Praktisi)
CREATE TABLE payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  practitioner_id UUID NOT NULL REFERENCES practitioner_profiles(user_id) ON DELETE RESTRICT,
  session_id UUID NOT NULL UNIQUE REFERENCES sessions(id) ON DELETE RESTRICT,
  gross_amount BIGINT NOT NULL CHECK (gross_amount >= 0),
  platform_fee_amount BIGINT NOT NULL CHECK (platform_fee_amount >= 0),
  net_amount BIGINT NOT NULL CHECK (net_amount >= 0),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'scheduled', 'processing', 'paid', 'held')),
  transfer_proof_url TEXT,
  due_at TIMESTAMPTZ NOT NULL,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 31. GMAIL_CONNECTIONS (Koneksi Read-Only Gmail & Token Terenkripsi AES-256-GCM)
CREATE TABLE gmail_connections (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  gmail_address TEXT NOT NULL,
  encrypted_refresh_token BYTEA NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked', 'error')),
  last_scanned_at TIMESTAMPTZ,
  connected_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 32. PRO_SUBSCRIPTIONS (Langganan Clarafin Pro, Unlimited, & Bonus Kuota Konsultasi)
CREATE TABLE pro_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  plan_type TEXT NOT NULL CHECK (plan_type IN ('pro_monthly', 'unlimited_monthly', 'unlimited_yearly', 'consult_bonus')),
  source_session_id UUID REFERENCES sessions(id) ON DELETE SET NULL,
  price_paid BIGINT NOT NULL CHECK (price_paid >= 0),
  quota_total INTEGER NOT NULL CHECK (quota_total = -1 OR quota_total > 0), -- -1 menandakan Unlimited
  quota_used INTEGER NOT NULL DEFAULT 0 CHECK (quota_used >= 0),
  xendit_invoice_id TEXT,
  status TEXT NOT NULL DEFAULT 'waiting_payment' CHECK (status IN ('waiting_payment', 'active', 'expired')),
  starts_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (quota_total = -1 OR quota_used <= quota_total)
);

-- 33. AI_USAGE_LEDGER (Buku Besar Kuota AI & Reservasi Atomik per Request)
CREATE TABLE ai_usage_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  request_id TEXT NOT NULL UNIQUE,
  month_year TEXT NOT NULL CHECK (month_year ~ '^[0-9]{4}-[0-9]{2}$'),
  action_type TEXT NOT NULL CHECK (action_type IN ('chat', 'quick_add', 'voice', 'ocr', 'gmail_sync')),
  surface_mode TEXT NOT NULL CHECK (surface_mode IN ('quick_sheet', 'full_screen', 'voice', 'ocr', 'gmail')),
  bucket TEXT NOT NULL CHECK (bucket IN ('free', 'pro', 'unlimited', 'bonus')),
  status TEXT NOT NULL DEFAULT 'reserved' CHECK (status IN ('reserved', 'success', 'failed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 34. PLATFORM_SETTINGS (Konfigurasi Operasional Terpusat Tanpa Deploy Ulang)
CREATE TABLE platform_settings (
  key TEXT PRIMARY KEY,
  value_json JSONB NOT NULL,
  updated_by UUID,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 35. AUDIT_EVENTS (Jejak Audit Sistem Immutable Tanpa FK Cascade)
CREATE TABLE audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID,
  actor_role TEXT NOT NULL CHECK (actor_role IN ('client', 'practitioner', 'staff', 'system')),
  event_type TEXT NOT NULL,
  target_table TEXT NOT NULL,
  target_id UUID,
  payload JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 36. DELETED_ACCOUNT_PAYMENT_ARCHIVES (Arsip Anonim Pajak 5 Tahun Pasca Hapus Akun)
CREATE TABLE deleted_account_payment_archives (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  original_session_id UUID NOT NULL,
  anonymized_user_hash TEXT NOT NULL,
  price_paid BIGINT NOT NULL,
  platform_cut_pct INTEGER NOT NULL,
  session_tier TEXT NOT NULL,
  session_channel TEXT NOT NULL,
  archived_payload_json JSONB NOT NULL DEFAULT '{}',
  session_completed_at TIMESTAMPTZ,
  archived_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  retain_until TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '5 years')
);
```

---

## 3. Strategi Indeks Performa Kritis

1. **Pencatat Keuangan & Aggregasi Saldo:**
   - `CREATE INDEX idx_transactions_user_occurred ON transactions (user_id, occurred_at DESC);`
   - `CREATE INDEX idx_transactions_user_category_date ON transactions (user_id, category, occurred_at DESC);`
   - `CREATE INDEX idx_ai_drafts_user_status ON ai_drafts (user_id, status, created_at DESC);`
   - `CREATE INDEX idx_budgets_user_month ON budgets (user_id, month_year);`
2. **Alokasi Kuota AI & Langganan:**
   - `CREATE INDEX idx_ai_ledger_user_month_status ON ai_usage_ledger (user_id, month_year, status);`
   - `CREATE INDEX idx_pro_subs_user_active ON pro_subscriptions (user_id, status, expires_at DESC);`
3. **Jadwal Praktisi, Checkout, & Sesi Aktif:**
   - `CREATE INDEX idx_sessions_client_status ON sessions (client_user_id, status, scheduled_start_at DESC);`
   - `CREATE INDEX idx_sessions_practitioner_status ON sessions (practitioner_id, status, scheduled_start_at);`
   - `CREATE INDEX idx_orders_user_status ON orders (user_id, status, created_at DESC);`
   - `CREATE INDEX idx_slot_holds_expiry ON booking_slot_holds (status, expires_at) WHERE status = 'held';`
4. **Ruang Chat Sesi & Audit:**
   - `CREATE INDEX idx_session_messages_session_time ON session_messages (session_id, created_at ASC);`
   - `CREATE INDEX idx_audit_events_target ON audit_events (target_table, target_id, created_at DESC);`

---

## 4. Aturan Row-Level Security (RLS) Supabase

Backend Go terhubung menggunakan **Service Role** (untuk transaksi atomik, reservasi kuota AI, webhook Xendit, escrow payout, dan operasi CMS internal), sementara **RLS** tetap diaktifkan di seluruh tabel agar akses langsung klien Supabase atau kebocoran token terisolasi ketat:

| Kelompok Tabel | Aturan Akses (`auth.uid()`) |
| :--- | :--- |
| `users`, `user_preferences`, `wallets`, `goals`, `goal_contributions`, `transactions`, `ai_drafts`, `budgets`, `bills`, `notifications`, `match_expert_submissions`, `pro_subscriptions`, `ai_usage_ledger` | Hanya dapat dibaca & diubah oleh pemilik baris (`user_id = auth.uid()` atau `id = auth.uid()` untuk `users`). Khusus `ai_usage_ledger` & `pro_subscriptions`: klien hanya memiliki hak `SELECT` (mutasi hanya via backend Go). |
| `categories`, `catalog_packages`, `problem_tags`, `venues`, `vouchers`, `practitioner_packages`, `practitioner_availability` | Dapat dibaca (`SELECT`) oleh pengguna terautentikasi jika aktif (`is_active = TRUE`), sedangkan mutasi `INSERT/UPDATE/DELETE` dikunci ke praktisi pemilik (`practitioner_id = auth.uid()`) atau Staff CMS. |
| `practitioner_profiles`, `staff_practitioner_pins` | Klien hanya dapat membaca baris `practitioner_profiles` dengan `status = 'verified'`; praktisi dapat membaca & memperbarui profilnya sendiri (`user_id = auth.uid()`). |
| `orders`, `payments`, `booking_slot_holds` | Pemilik order (`user_id = auth.uid()`) hanya memiliki hak `SELECT`; pembaruan status pembayaran dan konversi slot hanya dijalankan backend Go via webhook Xendit. |
| `sessions`, `session_messages`, `session_reviews`, `session_complaints` | Hanya dapat diakses oleh `client_user_id`, `partner_user_id`, atau `practitioner_id` pada sesi terkait. |
| `session_notes` | Hanya dapat dibuat/diperbarui oleh `practitioner_id` sebelum `locked_at`; dapat dibaca oleh `client_user_id` dan `partner_user_id` setelah disubmit. |
| `consents` | Dapat dibaca oleh praktisi sesi **hanya selama `status = 'active'` dan waktu sekarang sebelum `expires_at`**; hanya pemilik `user_id` yang berhak mencabut (`revoked`). |
| `gmail_connections` | Klien hanya membaca status/email (`SELECT`), **kolom `encrypted_refresh_token` diblokir dari akses klien** (hanya didekripsi backend Go). |
| `payouts`, `platform_settings`, `audit_events`, `deleted_account_payment_archives` | Akses klien diblokir total di level RLS (praktisi hanya dapat membaca `payouts` miliknya melalui endpoint backend terverifikasi). |
