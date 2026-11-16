# Entity Relationship Diagram & Database Specification (`erd.md`)

| Field | Value |
| --- | --- |
| Project | **Clarafin** (`apps/mobile`, `services/api`, `apps/web` [Landing Page + Advisor Portal + Staff CMS]) |
| Document Version | 2.0 (Existing Mobile App + AI Chatbot Blueprint + Rework Roadmap Aligned) |
| Status | Active Specification for `mobile_backend_integration` & `apps/web` |
| Database Engine | PostgreSQL (Supabase Managed Postgres) |
| Currency & Time | All backend monetary amounts in `BIGINT` (IDR, no decimals; display conversion via `preferred_currency`). All timestamps in `TIMESTAMPTZ` (business cutoffs evaluated in `Asia/Jakarta` / WIB). |

---

## 1. Tujuan & Cakupan Skema

Dokumen ini mendefinisikan **Entity Relationship Diagram (ERD)** dan spesifikasi **36 tabel kanonis** Clarafin yang diselaraskan penuh terhadap **kondisi kode eksisting di `apps/mobile`** dan **seluruh rencana pengembangan ke depan**:

1. **Entitas Aplikasi Mobile Eksisting (`apps/mobile` — Wave P1–P3):**
   - Auth & Profil (`authProvider`, `userProfileProvider`): multi-currency display (`IDR`, `USD`, `SGD`, `MYR`, `EUR`, `JPY`), preset avatar Notion (`selectedAvatarIndex`), preferensi notifikasi + *Daily Ritual* (`20:00 WIB`), PIN 6 digit & biometrik, serta 6-Step Onboarding (`trackingHistorySource`, `trackerFocuses` termasuk `networth`, multi-select `advisoryFocus`).
   - Smart Money Tracker (`walletsProvider`, `transactionsProvider`, `budgetsProvider`, `goalsProvider`, `billsProvider`, `notificationsProvider`): tipe dompet Web3/CEX/DEX/Investasi, `isAutoSync`, `customColorHex`, `returnPercentage`, `dividendDropDate`, `isVolatile`, transfer ke/dari Goal (`targetGoalId`), kontribusi multi-dompet ke Goal (`goal_contributions`), kategori Notion bertingkat (`categories`), serta kategori notifikasi `promo` & `actionLabel`.
   - Marketplace, Voucher, & Match Expert (`consultantsListProvider`, `bookingProvider`, `consultationSessionProvider`, `vouchersProvider`, `matchExpertProvider`): katalog 5 kategori (15 paket), multi-sesi (`1, 2, 3, 8` sesi), `onlineMethod`, `expectations` & lampiran pre-konsultasi, voucher diskon, `booking_code`, serta 12 dimensi kuesioner *Match Expert*.
2. **Entitas Rencana AI Chatbot & Monetisasi SaaS (`clarafin-ai-chatbot-blueprint.md`, `model-bisnis-ai-dan-saas.md`):**
   - SaaS Plan 3-tier (`free` 40/bulan, `pro_monthly` 400/30 hari, `unlimited` `-1`) + kesiapan *Opsi 2 Consult-to-Unlock* (`source_session_id`), `ai_usage_ledger` atomik & idempoten, `ai_drafts` multi-item/transfer, dan **tanpa tabel `ai_chat_sessions` / `ai_chat_messages`** karena percakapan `Clarafin AI` bersifat **ephemeral** (tombol `New Chat` menghapus sesi lama permanen di memori).
3. **Entitas Rework Backend, Web Portal Praktisi, & Staff CMS (`docs-rework-clarafin`, `PRD.md`, `implementation-plan.md` Wave P4–P5):**
   - Katalog master CMS (`catalog_packages`), `problem_tags` & maksimal 3 sematan praktisi (`staff_practitioner_pins`), `booking_slot_holds` di PostgreSQL (hold 15 menit Solo & 24 jam Couple), pemisahan `orders` + `payments` (Xendit QRIS idempoten untuk sesi & SaaS), siklus lengkap `sessions` (including 12h first-reply chat SLA, 3-day chat window, tombol `Hadir` 15m, Catatan Penutup 3 bagian, anti-leak flag, sengketa, payout 48h), `platform_settings`, `audit_events`, serta arsip kepatuhan 5 tahun (`deleted_account_payment_archives`).

---

## 2. Master Entity Relationship Diagram (Mermaid)

```mermaid
erDiagram
    USERS ||--|| USER_PREFERENCES : "has settings"
    USERS ||--o| PRACTITIONER_PROFILES : "applies via Web Portal"
    USERS ||--o{ WALLETS : "owns"
    USERS ||--o{ TRANSACTIONS : "records"
    USERS ||--o{ AI_DRAFTS : "reviews"
    USERS ||--o{ BUDGETS : "sets"
    USERS ||--o{ GOALS : "saves toward"
    USERS ||--o{ BILLS : "tracks"
    USERS ||--o{ NOTIFICATIONS : "receives"
    USERS ||--o| GMAIL_CONNECTIONS : "connects"
    USERS ||--o{ PRO_SUBSCRIPTIONS : "subscribes"
    USERS ||--o{ AI_USAGE_LEDGER : "consumes quota"
    USERS ||--o{ MATCH_EXPERT_SUBMISSIONS : "submits 12-step quiz"
    USERS ||--o{ ORDERS : "places"
    USERS ||--o{ SESSIONS : "books as client"
    USERS ||--o{ SESSIONS : "joins as couple partner"

    CATEGORIES ||--o{ CATEGORIES : "parent subcategory"
    CATEGORIES ||--o{ TRANSACTIONS : "categorizes"
    CATEGORIES ||--o{ BUDGETS : "limits"

    WALLETS ||--o{ TRANSACTIONS : "source wallet"
    WALLETS ||--o{ TRANSACTIONS : "destination wallet (transfer)"
    WALLETS ||--o{ AI_DRAFTS : "source wallet"
    WALLETS ||--o{ AI_DRAFTS : "destination wallet"
    WALLETS ||--o{ GOALS : "primary linked wallet"
    WALLETS ||--o{ GOAL_CONTRIBUTIONS : "contributes to goal"

    GOALS ||--o{ GOAL_CONTRIBUTIONS : "funded by multiple wallets"
    GOALS ||--o{ TRANSACTIONS : "transfer target goal"

    PRACTITIONER_PROFILES ||--o{ PRACTITIONER_PACKAGES : "activates & prices"
    PRACTITIONER_PROFILES ||--o{ PRACTITIONER_AVAILABILITY : "schedules"
    PRACTITIONER_PROFILES ||--o{ BOOKING_SLOT_HOLDS : "holds or books slot"
    PRACTITIONER_PROFILES ||--o{ STAFF_PRACTITIONER_PINS : "pinned by staff"
    PRACTITIONER_PROFILES ||--o{ SESSIONS : "handles"
    PRACTITIONER_PROFILES ||--o{ PAYOUTS : "withdraws"

    CATALOG_PACKAGES ||--o{ PRACTITIONER_PACKAGES : "master catalog item"
    PRACTITIONER_PACKAGES ||--o{ SESSIONS : "booked package"
    PROBLEM_TAGS ||--o{ STAFF_PRACTITIONER_PINS : "max 3 pins per tag"
    VENUES ||--o{ SESSIONS : "hosts offline session"

    VOUCHERS ||--o{ ORDERS : "applies discount"
    ORDERS ||--o{ PAYMENTS : "paid via Xendit"
    ORDERS ||--o{ SESSIONS : "provisions 1..8 sessions"
    ORDERS ||--o{ PRO_SUBSCRIPTIONS : "activates SaaS plan"
    ORDERS ||--o{ BOOKING_SLOT_HOLDS : "reserves slots"

    SESSIONS ||--o| BOOKING_SLOT_HOLDS : "occupies slot"
    SESSIONS ||--o{ CONSENTS : "grants wallet access"
    SESSIONS ||--o{ SESSION_MESSAGES : "contains chat"
    SESSIONS ||--o| SESSION_NOTES : "closed with 3-part note"
    SESSIONS ||--o| SESSION_REVIEWS : "rated by client"
    SESSIONS ||--o| SESSION_COMPLAINTS : "disputed via"
    SESSIONS ||--o| PAYOUTS : "settled via"
    SESSIONS ||--o{ PRO_SUBSCRIPTIONS : "grants bonus quota (Opsi 2)"

    USERS {
        uuid id PK
        text email UK
        text full_name
        date birth_date "nullable at signup (no 18+ block); required before booking"
        text phone "nullable"
        text avatar_url
        integer selected_avatar_index "nullable (1..6 preset Notion avatar)"
        bigint monthly_budget_limit "default 5000000 IDR"
        boolean onboarding_completed
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at "nullable"
    }

    USER_PREFERENCES {
        uuid user_id PK,FK
        boolean notifications_enabled "transaction notifications toggle"
        boolean session_reminders_enabled
        boolean bill_reminders_enabled
        boolean promo_alerts_enabled
        boolean daily_reminder_enabled "default true (tutup hari)"
        time daily_reminder_time_wib "default 20:00"
        text tracking_history_source "fresh_start | other_app | spreadsheet"
        text[] tracker_focuses "cashflow | budget | bills | goals | networth"
        text[] advisory_focuses "basic | medium | couple | umkm | premium"
        boolean biometric_enabled
        text pin_hash "nullable (6-digit PIN hash)"
        text preferred_currency "default IDR (IDR | USD | SGD | MYR | EUR | JPY display)"
        text preferred_language "Bahasa Indonesia | English"
        timestamptz updated_at
    }

    CATEGORIES {
        uuid id PK
        text slug UK "e.g. exp_fnb, sub_fnb_coffee, inc_income"
        text name "e.g. Food & Beverage, Coffee Shop"
        uuid parent_id FK "nullable, self-ref for subcategory"
        text group_name "DAILY NEEDS | HOUSEHOLD NEEDS | PERSONAL NEEDS | FINANCE | SERVICES | OTHERS | INCOME CATEGORIES"
        text type "income | expense"
        text emoji
        text icon_key
        text color_hex
        text bg_color_hex
        integer sort_order
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    WALLETS {
        uuid id PK
        uuid user_id FK
        text name
        text type "bank | ewallet | cash | deposit | mutual_fund | bond | stock | cex | dex | web3_wallet | crypto | other"
        text institution_code "bca | mandiri | bri | bni | bsi | jago | jenius | gopay | binance | phantom | etc."
        text account_number_masked "nullable (•••• 4829)"
        bigint balance "IDR bulat"
        boolean is_auto_sync "default false (synced 2-way with Gmail & SaaS plan)"
        text custom_color_hex "nullable (custom card swatch)"
        real return_percentage "nullable (investment yield %)"
        timestamptz dividend_drop_date "nullable"
        boolean is_volatile "default false (Crypto/Stock)"
        boolean has_claimed_dividend "default false"
        boolean is_archived
        timestamptz created_at
        timestamptz updated_at
    }

    TRANSACTIONS {
        uuid id PK
        uuid user_id FK
        uuid wallet_id FK
        uuid destination_wallet_id FK "nullable, wallet-to-wallet transfer"
        uuid target_goal_id FK "nullable, transfer to or from goal"
        uuid category_id FK "nullable, normalized CMS category"
        text type "income | expense | transfer"
        text category "e.g. Food & Beverage • Coffee Shop"
        bigint amount
        text title
        text note "nullable"
        timestamptz occurred_at
        text source "manual | ai_text | ai_voice | ocr | gmail"
        text client_mutation_id "nullable, unique per user for anti-double-tap idempotency"
        timestamptz created_at
    }

    AI_DRAFTS {
        uuid id PK
        uuid user_id FK
        uuid wallet_id FK "nullable"
        uuid destination_wallet_id FK "nullable, transfer draft"
        uuid batch_id "nullable, groups multi-item one-shot prompt"
        text source "ai_text | ai_voice | ocr | gmail"
        text external_ref_id "nullable, gmail message id"
        text client_mutation_id "nullable, unique per user for anti-double-tap confirm"
        text type "income | expense | transfer"
        text category
        bigint amount
        text title
        text merchant_or_note
        timestamptz occurred_at
        real confidence_score
        text status "pending_review | confirmed | discarded"
        timestamptz created_at
        timestamptz updated_at
    }

    BUDGETS {
        uuid id PK
        uuid user_id FK
        uuid category_id FK "nullable"
        text category
        text month_year "YYYY-MM"
        bigint limit_amount
        text icon_key "nullable"
        text color_hex "nullable"
        text bg_color_hex "nullable"
        boolean alert_80_sent
        boolean alert_100_sent
        timestamptz created_at
        timestamptz updated_at
    }

    GOALS {
        uuid id PK
        uuid user_id FK
        uuid linked_wallet_id FK "nullable (primary wallet ref)"
        text title
        bigint target_amount
        bigint saved_amount
        date target_date "nullable"
        text priority "urgent | needs | wants"
        text source_asset_label "nullable"
        text icon_key
        text tag_color_hex
        text tag_text_color_hex
        text status "active | completed | archived"
        timestamptz created_at
        timestamptz updated_at
    }

    GOAL_CONTRIBUTIONS {
        uuid id PK
        uuid goal_id FK
        uuid wallet_id FK
        bigint contributed_amount
        timestamptz updated_at
    }

    BILLS {
        uuid id PK
        uuid user_id FK
        text title
        text category "nullable"
        bigint amount
        date due_date "nullable"
        text frequency "once | weekly | monthly | yearly"
        boolean is_paid
        boolean auto_pay
        text icon_key "nullable"
        text icon_color_hex "nullable"
        text icon_bg_color_hex "nullable"
        timestamptz paid_at "nullable"
        timestamptz created_at
        timestamptz updated_at
    }

    NOTIFICATIONS {
        uuid id PK
        uuid user_id FK
        text category "session | transaction | budget | bill | promo | system"
        text title
        text body
        text action_route "nullable"
        text action_label "nullable (e.g. Lihat Sesi)"
        boolean is_read
        timestamptz created_at
    }

    PRACTITIONER_PROFILES {
        uuid user_id PK,FK
        text display_name
        text title_headline
        text bio
        text city
        text practitioner_tier "basic | medium | premium"
        integer clients_handled_count "<300 basic | 301..500 medium | >500 premium"
        text[] certifications
        text[] certificate_file_urls
        text ktp_file_url "nullable (KYC upload via Web)"
        text[] specializations
        text[] languages "Indonesia | Inggris | Mandarin | Arab | Jawa"
        text[] supported_methods "online | offline"
        text gender "nullable (Laki-laki | Perempuan)"
        integer birth_year "nullable (Match Expert age preference)"
        text consulting_style "nullable (Hangat & Suportif | To the point & solutif | Seimbang)"
        integer years_of_experience
        boolean is_fully_booked "default false"
        text status "pending | verified | suspended"
        integer platform_cut_pct "default 20, range 10..35"
        integer violation_count "default 0 (anti-leak 3-strike policy)"
        text bank_name
        text bank_account_number
        text bank_account_holder
        jsonb pending_bank_change_json "nullable (awaiting Staff CMS approval)"
        real rating_avg
        integer review_count
        integer total_sessions_completed "default 0 (ranking tie-breaker)"
        timestamptz verified_at
        timestamptz created_at
        timestamptz updated_at
    }

    CATALOG_PACKAGES {
        uuid id PK
        text code UK "e.g. personal_basic, couple_pre_marriage"
        text service_category "individual | couple | umkm | corporate | financial_checkup"
        text category_tag "e.g. Personal Advisory • Basic"
        text tier "basic | medium | premium | pre_marriage | marriage"
        text participant_type "solo | couple | group_family | corporate"
        text package_title "e.g. Fondasi Arus Kas & Utang"
        text short_desc
        text full_desc
        text[] features
        integer online_duration_minutes "45 | 60 | 90"
        integer offline_duration_minutes "default 90"
        bigint base_online_price_idr
        bigint max_online_price_idr
        bigint base_offline_price_idr
        bigint max_offline_price_idr
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    PRACTITIONER_PACKAGES {
        uuid id PK
        uuid practitioner_id FK
        uuid catalog_package_id FK
        text service_category "individual | couple | umkm | corporate | financial_checkup"
        text category_tag "e.g. Personal Advisory • Basic"
        text tier "basic | medium | premium | pre_marriage | marriage"
        text package_title
        integer duration_minutes "default 60"
        bigint online_price_idr "includes Call, Video, Chat"
        bigint offline_price_idr "nullable"
        boolean is_online_active
        boolean is_offline_active
        boolean is_active
    }

    PROBLEM_TAGS {
        uuid id PK
        text slug UK "e.g. pinjol, kpr, pajak, runway_usaha"
        text label "e.g. #Pinjol & Paylater"
        text min_tier "basic | medium | premium"
        boolean is_active
    }

    STAFF_PRACTITIONER_PINS {
        uuid id PK
        uuid problem_tag_id FK
        uuid practitioner_id FK
        integer priority_order "1..3 (max 3 per tag)"
        timestamptz created_at
    }

    PRACTITIONER_AVAILABILITY {
        uuid id PK
        uuid practitioner_id FK
        integer day_of_week "0=Sun .. 6=Sat"
        time start_time_wib
        time end_time_wib
        boolean is_active
    }

    BOOKING_SLOT_HOLDS {
        uuid id PK
        uuid practitioner_id FK
        uuid order_id FK "nullable"
        uuid session_id FK "nullable"
        timestamptz slot_start_at
        timestamptz slot_end_at
        text status "held | booked | released"
        timestamptz expires_at "15m Solo / 24h Couple"
        timestamptz created_at
    }

    VENUES {
        uuid id PK
        text name
        text city
        text address
        text maps_url
        boolean is_active
        timestamptz created_at
    }

    VOUCHERS {
        uuid id PK
        text code UK "e.g. CLARAFIN50, HALOFINCFP"
        text title
        text description
        text category "all | counseling | investment"
        text discount_type "fixed_idr | percentage"
        bigint discount_value
        bigint max_discount_idr "nullable"
        bigint min_transaction_idr "default 0"
        timestamptz valid_until
        integer usage_limit "nullable"
        boolean is_active
        timestamptz created_at
    }

    MATCH_EXPERT_SUBMISSIONS {
        uuid id PK
        uuid user_id FK
        jsonb answers_json "12 dimensions: method, target, languages, budget_tier, main_topic, specific_tags, etc."
        uuid[] top_practitioner_ids
        timestamptz created_at
    }

    ORDERS {
        uuid id PK
        text booking_code UK "e.g. HF-CFP-89210"
        uuid user_id FK
        text order_type "consultation_session | saas_pro | saas_unlimited"
        uuid voucher_id FK "nullable"
        text voucher_code "nullable"
        bigint subtotal_idr
        bigint bundle_discount_idr "7% for 3 sessions, 12% for 8 sessions"
        bigint platform_fee_idr "15000 for consultation, 0 for SaaS (no transaction fee)"
        bigint voucher_discount_idr "default 0"
        bigint total_paid_idr
        text payment_method "qris (launch) | va | ewallet"
        text status "waiting_partner | waiting_payment | paid | expired | cancelled | refunded"
        timestamptz expires_at
        timestamptz paid_at "nullable"
        timestamptz created_at
        timestamptz updated_at
    }

    PAYMENTS {
        uuid id PK
        uuid order_id FK
        text provider "xendit"
        text provider_reference_id UK "idempotent webhook reference"
        text qris_string "nullable"
        bigint amount_idr
        text status "pending | paid | expired | failed"
        jsonb raw_webhook_payload "nullable"
        timestamptz paid_at "nullable"
        timestamptz created_at
    }

    SESSIONS {
        uuid id PK
        uuid order_id FK "nullable (links 1..8 sessions in bundle)"
        text booking_code "nullable (display ref)"
        uuid client_user_id FK
        uuid partner_user_id FK "nullable, for couple"
        uuid practitioner_id FK
        uuid package_id FK "nullable, references practitioner_packages"
        text service_category "individual | couple | umkm | corporate | financial_checkup"
        text tier "basic | medium | premium | pre_marriage | marriage"
        text package_title
        text delivery_mode "online | offline (online auto-includes call, video, chat)"
        text online_method "call | video | chat | nullable"
        integer session_index "1..8 within bundle"
        integer session_count "1 | 2 | 3 | 8"
        uuid venue_id FK "nullable"
        timestamptz scheduled_start_at
        timestamptz scheduled_end_at
        bigint subtotal_price_idr
        bigint platform_fee_idr "default 15000 (no transaction fee)"
        text voucher_code "nullable"
        bigint discount_amount_idr "default 0"
        bigint price_paid "subtotal + platform_fee - discount"
        integer platform_cut_pct
        boolean terms_and_data_consent_accepted "unified single checkbox consent"
        text status "waiting_partner | waiting_payment | scheduled | ongoing | awaiting_notes | completed | disputed | cancelled | no_show_client | no_show_practitioner"
        text xendit_invoice_id "nullable"
        text xendit_qris_string "nullable"
        timestamptz payment_expires_at
        timestamptz partner_invite_expires_at
        timestamptz partner_accepted_at "nullable"
        text meet_url "nullable"
        timestamptz chat_window_expires_at "nullable (3 days for chat channel)"
        timestamptz practitioner_first_reply_at "nullable (12h first-reply SLA)"
        text[] intake_topics "BookingStep3 selected topics"
        text pre_consult_note "Kendala / tujuan (or AI chat intake summary)"
        text pre_consult_expectations "Harapan setelah konseling"
        text[] attachment_urls "Pre-consult uploaded files"
        timestamptz attendance_confirmed_at "nullable (client Hadir <=15m)"
        timestamptz practitioner_attended_at "nullable (practitioner Hadir <=15m)"
        integer reschedule_count "max 1, >=24h before start"
        bigint refund_amount_idr "default 0"
        timestamptz completed_at
        timestamptz payout_ready_at
        timestamptz created_at
        timestamptz updated_at
    }

    CONSENTS {
        uuid id PK
        uuid session_id FK
        uuid user_id FK
        uuid[] wallet_ids
        date date_from "nullable"
        date date_to "nullable"
        text status "active | revoked | expired"
        timestamptz granted_at
        timestamptz expires_at "completed_at + 7 days"
        timestamptz revoked_at "nullable"
    }

    SESSION_MESSAGES {
        uuid id PK
        uuid session_id FK
        uuid sender_user_id FK
        text body
        text attachment_url "nullable"
        boolean is_flagged_leak "default false (anti-leak contact filter)"
        timestamptz created_at
    }

    SESSION_NOTES {
        uuid session_id PK,FK
        text core_issue
        text action_steps
        text dont_rule
        timestamptz submitted_at
        timestamptz updated_at
        timestamptz locked_at "nullable (locked upon payout release)"
    }

    SESSION_REVIEWS {
        uuid session_id PK,FK
        uuid reviewer_user_id FK
        integer rating "1..5"
        text comment "nullable"
        boolean is_anonymized "default false (true on account delete)"
        timestamptz created_at
    }

    SESSION_COMPLAINTS {
        uuid id PK
        uuid session_id UK,FK
        uuid reporter_user_id FK
        text reason
        text evidence_url "nullable"
        text practitioner_response "nullable (1 allowed reply)"
        bigint refund_amount_idr "nullable"
        text status "open | resolved_practitioner | resolved_full_refund | resolved_partial_refund"
        text staff_resolution_note
        timestamptz created_at
        timestamptz resolved_at
    }

    PAYOUTS {
        uuid id PK
        uuid practitioner_id FK
        uuid session_id UK,FK
        bigint gross_amount
        bigint platform_fee_amount
        bigint net_amount
        text status "pending | scheduled | processing | paid | held"
        text transfer_proof_url "nullable"
        timestamptz due_at "48h after closing note or <24h client cancel"
        timestamptz paid_at "nullable"
        timestamptz created_at
    }

    GMAIL_CONNECTIONS {
        uuid user_id PK,FK
        text gmail_address
        bytea encrypted_refresh_token "AES-256-GCM"
        text status "active | revoked | error"
        timestamptz last_scanned_at
        timestamptz connected_at
    }

    PRO_SUBSCRIPTIONS {
        uuid id PK
        uuid user_id FK
        uuid order_id FK "nullable"
        text plan_type "pro_monthly | unlimited_monthly | unlimited_yearly | consult_bonus"
        uuid source_session_id FK "nullable (Opsi 2 Consult-to-Unlock expansion)"
        bigint price_paid
        integer quota_total "400 | -1 (unlimited) | bonus"
        integer quota_used
        text xendit_invoice_id "nullable"
        text status "waiting_payment | active | expired"
        timestamptz starts_at
        timestamptz expires_at
        timestamptz created_at
    }

    AI_USAGE_LEDGER {
        uuid id PK
        uuid user_id FK
        text request_id UK "idempotency key"
        text month_year "YYYY-MM in WIB"
        text action_type "chat | quick_add | voice | ocr | gmail_sync"
        text surface_mode "quick_sheet | full_screen | voice | ocr | gmail"
        text bucket "free | pro | unlimited | bonus"
        text status "reserved | success | failed"
        timestamptz created_at
    }

    PLATFORM_SETTINGS {
        text key PK "age_limits | chat_first_reply_sla_hours | payment_method_flags | platform_fee_idr"
        jsonb value_json
        uuid updated_by "nullable"
        timestamptz updated_at
    }

    AUDIT_EVENTS {
        uuid id PK
        uuid actor_user_id "nullable (survives user delete)"
        text actor_role "client | practitioner | staff | system"
        text event_type
        text target_table
        uuid target_id "nullable"
        jsonb payload
        timestamptz created_at
    }

    DELETED_ACCOUNT_PAYMENT_ARCHIVES {
        uuid id PK
        uuid original_session_id "nullable (no FK cascade)"
        text anonymized_user_hash "SHA-256"
        bigint price_paid
        integer platform_cut_pct
        text session_tier
        text session_channel
        jsonb archived_payload_json "anonymized 5-year compliance snapshot: profile, tracker summary, transcript, orders/refunds"
        timestamptz session_completed_at
        timestamptz archived_at
        timestamptz retain_until "archived_at + 5 years"
    }
```

---

## 3. Pemetaan State Frontend (`apps/mobile`) & Rencana Sistem ke Tabel Database

Tabel berikut memetakan seluruh provider/model yang **sudah berjalan di `apps/mobile`**, fitur **rencana AI Chatbot & Web**, serta memisahkan state mana yang persisten di PostgreSQL vs **terkomputasi (*derived*)** vs **ephemeral (memori saja)**:

| Provider / Model / Layar (`apps/mobile` & Rencana) | Tabel PostgreSQL Tujuan | Catatan Pemetaan & Sinkronisasi |
| --- | --- | --- |
| `authProvider` (`AuthUserModel`) | `auth.users` + `users` | Registrasi, login, dan sesi aktif. `birth_date` opsional saat registrasi cepat (tanpa blokir usia < 18 tahun) dan dilengkapi sebelum pemesanan sesi. |
| `userProfileProvider` (`UserProfile`) | `users` + `user_preferences` + `gmail_connections` + `pro_subscriptions` | Menyimpan profil dasar, `selected_avatar_index` (`1..6`), preferensi 4 toggle notifikasi + *Daily Ritual* (`daily_reminder_enabled`, `daily_reminder_time_wib`), PIN & biometrik, `preferred_currency` (`IDR`/`USD`/`SGD`/`MYR`/`EUR`/`JPY`), `preferred_language`, onboarding 6-step (`tracking_history_source`, `tracker_focuses` [`networth`], `advisory_focuses`), koneksi Gmail, & plan SaaS. |
| `walletsProvider` (`List<WalletModel>`) | `wallets` | Menyimpan seluruh kategori dompet (`Bank`, `E-Wallet`, `Cash`, `Deposit`, `Mutual Fund`, `Bond`, `Stock`, `CEX`, `DEX`, `Web3 Wallet`, `Crypto`), `institution_code` (`bca`, `mandiri`, `binance`, `phantom`, rencana `jago`/`jenius`), `account_number_masked`, `is_auto_sync`, `custom_color_hex`, `return_percentage`, `dividend_drop_date`, `is_volatile`, & `has_claimed_dividend`. |
| `transactionsProvider` (`List<TransactionModel>`) | `transactions` | Mendukung `expense`, `income`, dan `transfer` antar-dompet (`destination_wallet_id`) maupun transfer ke/dari Goal (`target_goal_id`). |
| `TransactionCategories` (`transaction_category_model.dart`) | `categories` | Master kategori bertingkat (`Main • Sub`) beserta `emoji`, `icon_key`, `color_hex`, `bg_color_hex`, dan `group_name` yang dapat dikelola via Staff CMS. |
| `AiDraftReviewScreen` & `GmailDraftsPromptSheet` | `ai_drafts` | Menyimpan draf hasil teks AI, suara AI, OCR struk, dan pindai email Gmail 30 hari (`pending_review` -> `confirmed` / `discarded`), mendukung multi-item (`batch_id`) dan `transfer`. |
| `budgetsProvider` + `monthlyTotalBudgetProvider` | `budgets` + `users.monthly_budget_limit` | Menyimpan batas anggaran total (`users.monthly_budget_limit`, default `5.000.000`) serta batas kategori bulanan + ikon/warna (`budgets`). `syncedBudgetsProvider` & `monthlyBudgetSummaryProvider` bersifat **computed** dari `transactions`. |
| `goalsProvider` (`List<GoalModel>`) | `goals` + `goal_contributions` | Menyimpan target tabungan, `priority` (`urgent \| needs \| wants`), `tag_color_hex`, `tag_text_color_hex`, dan pemecahan kontribusi multi-dompet (`GoalModel.contributions`) di `goal_contributions`. |
| `billsProvider` (`List<BillModel>`) | `bills` | Menyimpan tagihan jatuh tempo (`due_date` nullable), frekuensi berulang, status lunas (`is_paid`), `auto_pay`, dan metadata ikon/warna. |
| `notificationsProvider` (`List<NotificationItem>`) | `notifications` | Menyimpan inbox notifikasi beserta `category` (`transaction`, `session`, `promo`, `system`, dll.), `is_read`, `action_route`, dan `action_label`. |
| `aiQuotaProvider` (`AiQuotaState`) | `pro_subscriptions` + `ai_usage_ledger` | Single Source of Truth kuota AI (`free` 40/bln, `pro_monthly` 400/30 hari, `unlimited` `-1`, plus kesiapan `consult_bonus` Opsi 2). `quickActionLimitProvider` lama dipensiunkan. |
| `UnifiedAiChatNotifier` (`AiChatScreen` & Quick Action AI — *Rencana*) | **Tidak ada tabel DB (Ephemeral)** | Sesuai `clarafin-ai-chatbot-blueprint.md`, percakapan `Clarafin AI` hidup hanya di memori `Riverpod`. Saat user menekan **`New Chat`**, sesi lama dihapus permanen tanpa tabel `ai_chat_sessions` / `ai_chat_messages`. |
| `vouchersProvider` & `VoucherSelectionSheet` | `vouchers` | Katalog kode promo (`CLARAFIN50`, `HALOFINCFP`, `NEWUSER5`, dll.) beserta jenis potongan, masa berlaku, dan batas pemakaian (dikelola di CMS). |
| `matchExpertProvider` (`MatchExpertState`) | `match_expert_submissions` + `practitioner_profiles` + `problem_tags` | Menyimpan hasil kuesioner 12 dimensi (`answers_json`) & rekomendasi top 3 agar dapat dibaca ulang sebagai sinyal konteks (*Retrieval Layer 3 S2*) di `Clarafin AI`. |
| `consultantsListProvider` (`ConsultantRepository`) & `BookingServiceMockData` | `practitioner_profiles` + `catalog_packages` + `practitioner_packages` + `practitioner_availability` + `venues` | Menyelaraskan 6 praktisi kanonis (`c1`–`c6`), 15 paket dalam 5 kategori (`catalog_packages`), harga & kanal aktif praktisi, jadwal mingguan (untuk pencocokan slot 14 hari), serta metadata `gender`, `birth_year`, `languages`, dan `consulting_style`. |
| `bookingProvider` (`BookingState`) & `consultationSessionProvider` | `orders` + `payments` + `booking_slot_holds` + `sessions` + `consents` + `session_messages` + `session_notes` + `session_reviews` + `session_complaints` + `payouts` | Mendukung pemesanan 1, 2, 3, atau 8 sesi dalam 1 `order` (`booking_code`), hold slot 15m/24h di Postgres, Xendit QRIS idempoten, `online_method`, `intake_topics`, `pre_consult_note`, `pre_consult_expectations`, lampiran, `Hadir` 15m, Catatan Penutup 3 bagian, komplain, review, dan pencairan 48h. |
| `dailyPnlProvider`, `financialHealthProvider` (`/score`), `ReportDashboardScreen`, `KprSimulationScreen`, `FinancialCalculatorScreen`, `DebtPayoffStrategyScreen`, `ExportDataScreen` | **Derived / Computed / Stateless** | Dihitung langsung secara dinamis dari agregasi `wallets`, `transactions`, `budgets`, `goals`, dan `bills` (atau kalkulator lokal), tidak memerlukan tabel persisten tersendiri. |
| Web Portal Praktisi & Staff CMS (`apps/web` — *Rencana Wave P5*) | `practitioner_profiles`, `catalog_packages`, `problem_tags`, `staff_practitioner_pins`, `venues`, `vouchers`, `platform_settings`, `audit_events`, `deleted_account_payment_archives` | Pendaftaran calon praktisi (`ktp_file_url`, sertifikat, rekening), verifikasi & override komisi `10%–35%`, sematan maksimal 3 praktisi per tag, pengelolaan venue/voucher/kategori/settings, resolusi sengketa, dan pencairan payout. |

---

## 4. Aturan Integritas & Kepatuhan Skema

1. **Integritas Saldo Dompet, Multi-Wallet Goal, & Idempotensi Mutasi (`Transactional Ledger`):**
   - Konfirmasi `ai_drafts` (`status = 'confirmed'`) atau pencatatan `transactions` baru (termasuk transfer antar-dompet atau transfer ke/dari `target_goal_id`) wajib berjalan dalam satu transaksi ACID (`BEGIN ... COMMIT`) yang sekaligus memperbarui `wallets.balance`, `goals.saved_amount`, dan `goal_contributions.contributed_amount`, dengan proteksi `UNIQUE(user_id, client_mutation_id)` agar *double-tap* tidak pernah menggandakan mutasi.
   - Total `goals.saved_amount` wajib selalu sinkron dengan `SUM(goal_contributions.contributed_amount)`.
2. **Privasi Ephemeral `Clarafin AI`, `New Chat`, & Atomic Quota Reservation:**
   - Database PostgreSQL **sengaja tidak menyimpan** riwayat percakapan `Clarafin AI` (`no ai_chat_sessions / ai_chat_messages`). Pemanggilan alat baca oleh AI (`get_user_wallets`, `get_cashflow_summary`, `get_budget_and_bills_status`) selalu dikunci oleh `user_id` dari JWT terverifikasi.
   - Setiap panggilan AI melakukan reservasi kuota atomik (`status = 'reserved'` di `ai_usage_ledger` dengan `UNIQUE(request_id)`) sebelum memanggil Gemini; bila proses gagal sebelum jawaban selesai, status dikompensasi menjadi `'failed'`.
3. **Lock Dua Arah SaaS Plan <-> Gmail Auto-Sync <-> Dompet:**
   - Pengguna tanpa langganan aktif (`pro_subscriptions.status = 'active'` pada plan `pro_monthly`, `unlimited_*`, atau `consult_bonus`) berada di tier `free` (40 aksi/bulan): `gmail_connections` dan `wallets.is_auto_sync = TRUE` tidak diaktifkan untuk auto-sync hingga upgrade berhasil.
4. **Integritas Hold Slot, Multi-Sesi, & Pembayaran Idempoten:**
   - Kunci sementara jadwal (`booking_slot_holds`) disimpan di PostgreSQL (`15 menit` Solo / `24 jam` Couple) agar tahan terhadap restart proses Go.
   - Satu `orders` (baik 1 sesi maupun bundling 3/8 sesi dengan diskon 7%/12%) diproses melalui `payments` dengan `UNIQUE(provider_reference_id)` sehingga webhook Xendit bersifat idempoten dan tidak pernah menggandakan sesi atau link Google Meet.
5. **Isolasi Izin Dompet Per Sesi (`consents`):**
   - Endpoint ringkasan klien untuk praktisi (`GET /v1/sessions/:id/client-summary`) wajib memverifikasi:
     - `sessions.practitioner_id = auth.uid()`
     - `sessions.status IN ('scheduled', 'ongoing', 'awaiting_notes')`
     - `consents.status = 'active'` dan `NOW() < consents.expires_at` (`completed_at + 7 hari`)
     - Agregasi hanya mencakup `wallets.id = ANY(consents.wallet_ids)` (jika `wallet_ids` dipilih spesifik) dalam rentang `date_from..date_to`.
6. **Multi-Currency Display vs IDR Ledger:**
   - `USER_PREFERENCES.preferred_currency` hanya memengaruhi format tampilan di sisi klien; seluruh nominal di database (`wallets.balance`, `transactions.amount`, `budgets`, `goals`, `bills`, `orders`, `payouts`) disimpan dan dihitung dalam **IDR bilangan bulat (`BIGINT`)**.
7. **Kepatuhan Retensi 5 Tahun Saat Hapus Akun:**
   - Saat `DELETE /v1/me` dipanggil (dan pengguna tidak memiliki sesi aktif maupun payout tertunda jika berstatus praktisi), sistem menyalin ringkasan kepatuhan ke `deleted_account_payment_archives` tanpa FK cascade (`anonymized_user_hash = SHA-256`, retensi 5 tahun), menyamarkan ulasan (`session_reviews.is_anonymized = TRUE`), mencabut token OAuth Gmail, mencatat ke `audit_events`, lalu menghapus akun di `users` (`ON DELETE CASCADE` untuk data personal aktif).
