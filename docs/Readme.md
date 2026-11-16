# Clarafin Documentation Index

Selamat datang di repositori dokumentasi resmi **Clarafin** (sebelumnya dikenal sebagai HaloFin pada prototipe awal). Clarafin adalah ekosistem finansial personal berbasis aplikasi mobile (**Flutter**) yang menggabungkan:
1. **Marketplace Konsultasi Keuangan Bersertifikat** (CFP, QWP, AEPP, Brevet Pajak,Akuntan/Konsultan Keuangan) dengan katalog layanan terstandarisasi (**Basic**, **Medium**, **Premium**) untuk **1 Orang** maupun **Pasangan (Couple)**.
2. **Pencatat Keuangan Personal Gratis (Money Tracker)** yang mencakup manajemen multi-dompet (`Wallet`), anggaran (`Budget`), target tabungan (`Goals`), tagihan (`Bills`), laporan arus kas (`Report`), serta pemindaian mutasi/resi email otomatis via **Gmail Read-Only OAuth (30 Hari)**.
3. **Asisten AI Finansial Berkuota** untuk pencatatan transaksi natural (teks, suara, struk OCR) dan tanya-jawab edukasi keuangan dengan protokol ***helpful hint* netral yang tidak berlebihan + *soft boundary*** (tidak memberi instruksi produk/keputusan mengikat, melainkan memberi pemahaman awal lalu mengarahkan ke rekomendasi card praktisi manusia bersertifikat).

---

## 1. Prinsip Utama & Keputusan Produk Terkunci (Rework Baseline)

Dokumentasi ini telah diselaraskan dengan spesifikasi `docs-rework-clarafin` serta keputusan arsitektur tim:

1. **Strategi Delivery Frontend-First (`mobile_frontend`):**
   - Pengembangan dilakukan secara berurutan dimulai dari penguncian **UI/UX, Navigasi (`go_router`), dan Local State (`Riverpod` + `SharedPreferences`)** di aplikasi mobile hingga seluruh alur tervalidasi penuh.
   - Implementasi **Go Application Service (`services/api`)**, **Supabase Postgres & Auth**, dan **CMS Staff (`apps/cms`)** baru dieksekusi pada fase `mobile_backend_integration` setelah seluruh kontrak UI terkunci.
2. **Arsitektur Navigasi Bawah (Bottom Navigation Override):**
   - Aplikasi mobile mempertahankan **4-Tab + Center Action Button (`+`)** yang sudah berjalan di aplikasi saat ini: **`Home`**, **`Consult`**, **`FAB (+)`** (Quick Action / Catat Transaksi), **`Wallet`**, dan **`Budget`** (dengan 3 sub-tab: *Goals*, *Budget*, *Bills*), ditambah **Floating Session Button** di kanan bawah `Home` yang mengarah ke inbox sesi (`/session`).
3. **Katalog Paket, Tiering Praktisi, & Harga Checkout:**
   - Layanan dikelompokkan dalam 5 kategori utama (**Individu / Personal Advisory**, **Couple & Keluarga / Couple Advisory**, **UMKM & Bisnis**, **Corporate**, dan **Tes Finansial / Financial Check-Up**) dengan 3 tingkat kualifikasi praktisi (**Basic `<300 klien`**, **Medium `301–500 klien`**, **Premium `>500 klien`**).
   - Saat klien memilih layanan **Online**, setiap paket **otomatis mencakup fasilitas Call, Video Call, dan Chat (60 menit/sesi)** tanpa perbedaan harga antar metode online. Klien juga dapat memilih paket multi-sesi (**1 Sesi**, **2 Sesi**, **3 Sesi [Lebih Hemat -7%]**, **8 Sesi [-12%]**).
   - Pada halaman pembayaran (`BookingPaymentScreen`), komponen biaya terdiri dari **Subtotal Paket + Platform Fee (Rp 15.000) - Diskon Voucher Promo** (tanpa tambahan *Transaction Fee*). Spesifikasi lengkap mengacu pada **[Katalog Paket, Kualifikasi Praktisi, & Harga (`katalog-paket-dan-harga.md`)](./katalog-paket-dan-harga.md)**.
4. **Pembayaran, Kehadiran, & Pencairan Dana (Escrow Flow):**
   - Pembayaran menggunakan **QRIS via Xendit** (batas bayar **15 menit** untuk sesi 1 orang; batas undangan **24 jam** + **15 menit** bayar untuk sesi Couple).
   - Klien wajib menekan tombol **`Hadir`** pada sesi mulai hingga **+15 menit**.
   - Setelah sesi selesai (`awaiting_notes`), praktisi wajib mengisi **Catatan Penutup 3 Bagian** (*Inti Masalah*, *Langkah 30 Hari*, *Aturan Jangan Dilakukan*) dalam **24 jam**. Dana cair ke saldo praktisi **48 jam** setelah catatan terkirim (jika tanpa keluhan terbuka).
5. **Batas AI, Model Bisnis SaaS (`Free / Pro / Unlimited`), & Sinkronisasi Gmail-Dompet:**
   - Mengacu pada **[Model Bisnis AI, SaaS Plan, & Koneksi Gmail (`model-bisnis-ai-dan-saas.md`)](./model-bisnis-ai-dan-saas.md)**, terdapat 2 opsi model bisnis kuota AI (Opsi 1: Model SaaS Berjenjang; Opsi 2: *Consult-to-Unlock* dari booking sesi advisor). Implementasi saat ini mengunci **Opsi 1 (SaaS)**: **Free Plan (40 aksi AI/bulan)**, **Clarafin Pro Bulanan (Rp 49.000 / 30 hari — 400 aksi AI + Gmail Sync Bulanan)**, dan **Clarafin Unlimited (Rp 99.000 / 30 hari — Unlimited aksi AI + Unlimited Gmail Sync)**.
   - Kartu Koneksi Gmail di `ProfileScreen` terhubung dua arah dengan tombol On/Off Auto-Sync pada daftar institusi dompet (`AddWalletInstitutionScreen` & `WalletDetailScreen`). Saat pengguna berada di *Free Plan*, tombol On/Off diganti menjadi tombol **`Upgrade Plan`**.
6. **Pemisahan Aplikasi Mobile (Murni Klien, Tanpa Batas Usia 18+) vs Ekosistem Web 3-Pintu:**
   - **Aplikasi Mobile (`apps/mobile`)** dikhususkan 100% untuk klien/pengguna umum (termasuk remaja/pelajar di bawah 18 tahun yang sudah berpenghasilan dan ingin belajar mengelola keuangan).
   - **Ekosistem Web** mencakup 3 pintu: (1) **Public Landing Page + Form Pendaftaran Praktisi**, (2) **Web Portal Praktisi (Advisor Dashboard)** untuk operasional konsultan terverifikasi, dan (3) **Web Internal Staff CMS** untuk verifikasi praktisi, pengaturan tier & komisi, pengelolaan venue/voucher, dan pencairan dana.
7. **Privasi & Persetujuan Layanan Terpadu:**
   - Persetujuan klien atas syarat konsultasi dan izin pembacaan ringkasan profil finansial selama sesi berlangsung disatukan dalam **1 kotak centang Syarat & Ketentuan Layanan** pada alur pemesanan.
   - Penghapusan akun menghapus seluruh data finansial personal dan memutuskan token Gmail, namun mengarsipkan riwayat transaksi pembayaran sesi selama **5 tahun** untuk kepatuhan pajak/audit.

---

## 2. Daftar Isi Dokumentasi

### Produk & Domain
- **[Product Requirements Document (PRD)](./PRD.md)** — Visi produk, katalog layanan, siklus hidup sesi & pembayaran, aturan AI & data klien, serta fase delivery.
- **[Katalog Paket, Kualifikasi Praktisi, & Strategi Harga](./katalog-paket-dan-harga.md)** — Spesifikasi resmi paket `Online` (Call/Video/Chat) vs `Offline`, penamaan paket yang "nge-hook" + tag kategori (`Personal Advisory`, `Couple Advisory`, `UMKM Advisory`, `Corporate Wellness`, `Financial Check-Up`), klasifikasi praktisi (`<300`, `301–500`, `>500` klien), serta aturan `Platform Fee` & `Voucher`.
- **[Model Bisnis Kuota AI, Langganan SaaS, & Koneksi Gmail](./model-bisnis-ai-dan-saas.md)** — Spesifikasi 2 opsi model bisnis kuota AI (SaaS `Free / Pro Bulanan / Unlimited` vs *Consult-to-Unlock* dari sesi advisor), keterkaitan Kartu Koneksi Gmail di Profil dengan tombol On/Off Auto-Sync di daftar dompet, serta pemisahan Mobile App vs Web Portal Praktisi & Landing Page.
- **[Spesifikasi Rework Onboarding 6-Step](./rework-onboarding.md)** — Desain alur onboarding baru yang menggabungkan pengalaman *Smart Money Tracker* (adaptasi *Oyenza*: hook harian, riwayat catat/impor CSV, fokus fitur + *Live Mini-Dashboard Preview*, setup dompet & target, serta ritme malam `20:00 WIB`) dengan **Pemetaan Topik Konsultasi Advisor (`CFP®/CFA®/QWP®/BKP`)** dan sinkronisasi 2 arah ke `Profile -> Pengaturan Notifikasi`.
- **[Canonical Glossary](./glossary.md)** — Kamus istilah domain resmi, status siklus hidup (`SessionStatus`, `DraftStatus`), dan aturan penamaan lintas dokumen.

### Arsitektur & Spesifikasi Teknis (`docs/tech/`)
- **[System Architecture](./tech/Architecture.md)** — Topologi sistem 2-repo (`apps/mobile`, `apps/cms`, `services/api`), komponen Supabase + Go + Redis + Xendit + Google APIs, serta pemisahan fase `mobile_frontend` vs `mobile_backend_integration`.
- **[Entity Relationship Diagram & Database Schema (ERD)](./tech/erd.md)** — Spesifikasi lengkap skema database PostgreSQL (36 tabel kanonis: domain tracker eksisting + kategori + multi-wallet goal + voucher + Match Expert + order/payment/hold + marketplace, sesi, AI quota, Gmail OAuth, CMS settings/audit, dan arsip kepatuhan).
- **[Database Strategy](./tech/database.md)** — DDL SQL lengkap, strategi Row-Level Security (RLS), indeks, migrasi, dan retensi data.
- **[Frontend Mobile Specification](./tech/Frontend.md)** — Standar Neo-Brutalism Clarafin (`DESIGN_SYSTEM.md`), peta rute (`go_router`), arsitektur fitur, dan kontrak layar.
- **[Backend Service Specification](./tech/Backend.md)** — Arsitektur Go Application Service (`chi`, `pgx/v5`), background cron jobs, integrasi Xendit/Google/Gemini, dan standar error.
- **[API Design Guidelines](./tech/api-design.md)** — Kontrak endpoint RESTful `/v1/`, webhook Xendit, idempotency, rate limiting, dan standar payload JSON.
- **[Technology Stack](./tech/Techstack.md)** — Matriks versi runtime dan library yang dikunci untuk Flutter, Go, Next.js CMS, dan Supabase.
- **[Security & Compliance](./tech/Security.md)** — Threat model (STRIDE), enkripsi token Gmail AES-256-GCM, kepatuhan UU PDP, dan isolasi akses data.
- **[Testing Strategy](./tech/testing-strategy.md)** — Strategi pengujian unit, widget, dan integrasi.

### Panduan Operasional (`docs/guides/`)
- **[Development Setup](./guides/dev-setup.md)** — Panduan menjalankan lingkungan pengembangan lokal.
- **[Engineering Standards](./guides/engineering-standards.md)** — Konvensi kode, branch, dan review.
- **[CI/CD Pipeline](./guides/ci-cd-pipeline.md)** — Otomatisasi lint, test, dan deployment.
- **[Design Assets Catalog](./guides/design-assets-catalog.md)** — Katalog referensi aset visual.
