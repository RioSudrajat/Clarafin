# Backend Service Specification — Clarafin (`services/api`)

| Field | Value |
| --- | --- |
| Project | **Clarafin** |
| Document Version | 3.0 (Rework Aligned) |
| Status | Active Specification for `mobile_backend_integration` |
| Runtime | Go `1.26.1` (`go-chi/chi/v5`, `jackc/pgx/v5`, `sqlc`, `uber-go/zap`) |

---

## 1. Peran & Cakupan `services/api`

`services/api` adalah layanan tunggal Go yang menjadi pusat aturan bisnis Clarafin untuk dua permukaan aplikasi (`apps/mobile` dan `apps/cms`). Sesuai strategi **Frontend-First**, layanan ini diimplementasikan pada fase `mobile_backend_integration` setelah seluruh UI/UX dan kontrak state di `apps/mobile` dikunci.

### Tanggung Jawab Utama
1. **Manajemen Profil, Preferensi, & Penghapusan Akun Terarsip (`5 Tahun`):** Mengelola data pengguna, validasi usia minimal 18 tahun (`birth_date`), serta prosedur penghapusan akun yang menyalin riwayat pembayaran sesi ke `deleted_account_payment_archives`.
2. **Sinkronisasi Pencatat Keuangan Personal:** CRUD `wallets`, `transactions`, `budgets`, `goals`, `bills`, dan `notifications` dengan jaminan atomisitas saldo dompet.
3. **Orkestrasi Sesi Konsultasi & Pembayaran Xendit QRIS:**
   - Mengunci slot waktu (**15 menit** untuk Solo, **24 jam** undangan + **15 menit** bayar untuk Couple).
   - Membuat invoice QRIS dinamis Xendit dan memverifikasi callback webhook Xendit (`X-Callback-Token` / HMAC).
   - Membuat tautan Google Meet unik untuk sesi kanal `virtual`.
   - Mencatat bukti kehadiran `Hadir` (batas **15 menit** sejak sesi mulai).
   - Memvalidasi pengiriman **Catatan Penutup 3 Bagian** (`session_notes`) oleh praktisi maksimal **24 jam** setelah sesi berakhir, lalu menjadwalkan pencairan dana **48 jam** kemudian (`payout_ready_at`).
4. **Penegakan Izin Dompet Per Sesi (`consents`):** Menyediakan endpoint `GET /v1/sessions/:id/client-summary` bagi praktisi yang hanya menghitung agregasi dari `wallet_ids` yang berstatus `active` pada sesi tersebut.
5. **Kuota AI, Strict Two-Pass Gemini, & Guardrail *Helpful Hint* Netral:**
   - Memeriksa rate limit Redis (`10 req/menit`) dan melakukan reservasi kuota atomik di `ai_usage_ledger` dengan `client_request_id` (**40 aksi gratis/bulan** reset tgl 1 pukul 00:00 WIB, **400 aksi Clarafin Pro** Rp 49.000 / 30 hari, atau **Unlimited** Rp 99.000 / 30 hari); dikompensasi bila gagal.
   - Menjalankan orkestrasi **Strict Two-Pass** (`Pass 1`: tool calling + sub-call `google_search` grounding terpisah; `Pass 2`: sintesis JSON `responseSchema` + validasi Go struct), *Zero-Trust* sanitasi `session_history` (maks 8–10 giliran, tolak role non-`user`/`model`), serta normalisasi kategori kanonis `TransactionCategories`.
   - Memasang *System Instruction* yang mengizinkan ***helpful hint* edukatif secara netral, seimbang, dan tidak berlebihan** (tanpa memilihkan tindakan mengikat atau merekomendasikan produk spesifik) agar pengguna tetap terdorong berkonsultasi dan menutup dengan rekomendasi paket + **1–3 card praktisi terverifikasi**.
6. **Pemindaian Email Mutasi 30 Hari via Gmail Read-Only OAuth:**
   - Mengenkripsi refresh token Google OAuth menggunakan **AES-256-GCM** sebelum disimpan ke `gmail_connections`.
   - Mengambil email mutasi bank/resi pembayaran digital dari **30 hari terakhir**, mengekstrak nominal & merchant menjadi `ai_drafts` (`pending_review`), dan langsung membuang isi mentah email dari memori.

---

## 2. Struktur Direktori `services/api`

```text
services/api/
├── cmd/
│   └── api/
│       └── main.go                 # Entrypoint HTTP server + Cron scheduler
├── internal/
│   ├── config/                     # Env & secret loader (fail-fast validation)
│   ├── middleware/                 # Supabase JWT auth, role guard (user/practitioner/staff), rate limiter, zap logger
│   ├── domain/                     # Domain structs & status constants
│   ├── repository/                 # sqlc generated queries & pgx transaction helpers
│   ├── service/
│   │   ├── tracker_service.go      # Wallets, transactions, budgets, goals, bills
│   │   ├── catalog_service.go      # Practitioners, Basic/Medium/Premium packages, venues
│   │   ├── session_service.go      # Booking Solo/Couple, attendance, 3-part notes, reschedule, cancel, complaints
│   │   ├── consent_service.go      # Per-session wallet consent & practitioner summary view
│   │   ├── ai_service.go           # Atomic quota ledger, Redis rate limit, Two-Pass Gemini, zero-trust history, helpful hint guardrail
│   │   ├── gmail_service.go        # Google OAuth, AES-256-GCM token encryption, 30-day receipt scanner
│   │   └── cms_service.go          # Staff verification, commission override (10-35%), dispute resolution, payouts
│   ├── handler/                    # HTTP handlers (/v1/*)
│   ├── adapter/
│   │   ├── xendit/                 # QRIS invoice creation & webhook verification
│   │   ├── google/                 # Gmail API (readonly) & Google Calendar/Meet API
│   │   └── gemini/                 # Google GenAI SDK wrapper
│   └── worker/                     # 5 background cron jobs
├── db/
│   ├── migrations/                 # Sequential .up.sql and .down.sql files
│   └── queries/                    # SQL files for sqlc
├── Dockerfile
└── go.mod
```

---

## 3. Jadwal Background Workers (`internal/worker`)

| Nama Worker | Jadwal | Logika Eksekusi |
| --- | --- | --- |
| `ExpireUnpaidAndInvites` | Tiap 1 menit | Mengubah `sessions` berstatus `waiting_payment` yang melewati `payment_expires_at` (15m) dan `waiting_partner` yang melewati `partner_invite_expires_at` (24h) menjadi `cancelled`. |
| `EvaluateSessionAttendance` | Tiap 5 menit | Untuk `sessions` berstatus `ongoing` yang telah melewati `scheduled_start_at + 15 minutes` dengan `attendance_confirmed_at IS NULL`, ubah status menjadi `no_show_client` dan buat instruksi refund 50% + hak praktisi 50%. |
| `RemindOverdueClosingNotes` | Tiap 1 jam | Mencari `sessions` berstatus `awaiting_notes` yang melewati `scheduled_end_at + 24 hours` tanpa baris di `session_notes`, lalu mengirim notifikasi peringatan ke praktisi dan menandainya di dashboard CMS Staff. |
| `QueueReadyPayouts` | Tiap 15 menit | Mencari `sessions` berstatus `completed` dengan `NOW() >= payout_ready_at` dan tanpa `session_complaints` berstatus `open`, lalu memasukkan baris baru ke tabel `payouts` (`status = 'pending'`). |
| `ScanConnectedGmailReceipts` | Tiap 6 jam | Memindai email mutasi/resi baru (maksimal umur email 30 hari) untuk akun dengan `gmail_connections.status = 'active'` dan menyimpannya ke `ai_drafts` (`source = 'gmail'`, `status = 'pending_review'`). |
