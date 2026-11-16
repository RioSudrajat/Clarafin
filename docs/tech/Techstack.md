# Technology Stack — Clarafin

| Field | Value |
| --- | --- |
| Project | **Clarafin** |
| Document Version | 3.0 (Rework Aligned) |
| Status | Active Baseline |
| Last Updated | 2026-11-01 |

---

## 1. Struktur Monorepo & App Surfaces

```text
clarafin/
├── apps/
│   ├── mobile/        # Flutter 3.41.2 (Android & iOS — Klien & Mode Praktisi Terverifikasi)
│   └── cms/           # Next.js 16.x (Web Internal Staff Clarafin)
├── services/
│   └── api/           # Go 1.26.x REST API & Cron Workers
└── docs/              # Dokumentasi Produk, Arsitektur, ERD, dan Panduan
```

---

## 2. Matriks Teknologi per Layer

### 2.1 Mobile Application (`apps/mobile`)
| Komponen | Teknologi | Status | Catatan |
| --- | --- | --- | --- |
| Framework | Flutter `3.41.2` (Dart `3.x`) | Selected | Single codebase Android & iOS |
| State Management | `flutter_riverpod` `^2.6.1` / `3.x` | Selected | Feature-first Notifiers |
| Routing | `go_router` `^14.8.1` | Selected | `StatefulShellRoute.indexedStack` untuk 4-branch Bottom Nav |
| Typography | `google_fonts` (Plus Jakarta Sans & Quicksand) | Selected | Standar `DESIGN_SYSTEM.md` |
| Icons | `lucide_icons` | Selected | Ikonografi bersih dengan stroke konsisten |
| Local Persistence (`mobile_frontend`) | `shared_preferences` | Selected | Menyimpan state per user ID selama fase Frontend-First |
| HTTP Client (`mobile_backend_integration`) | `dio` | Selected | Digunakan saat integrasi ke `services/api` dimulai |

### 2.2 Backend Service (`services/api`)
| Komponen | Teknologi | Status | Catatan |
| --- | --- | --- | --- |
| Runtime | Go `1.26.1` | Selected | Binary statis ringan |
| HTTP Router | `go-chi/chi/v5` | Selected | Idiomatis dan kompatibel penuh dengan `net/http` |
| Database Driver & Pool | `jackc/pgx/v5` (`pgxpool`) | Selected | Koneksi langsung ke PostgreSQL |
| SQL Codegen | `sqlc` | Selected | Type-safe SQL tanpa overhead ORM |
| Migrations | `golang-migrate` / `goose` | Selected | Pasangan `.up.sql` dan `.down.sql` bernomor urut |
| Logging | `uber-go/zap` | Selected | Structured JSON logging |
| Encryption | Go `crypto/aes` + `crypto/cipher` (AES-256-GCM) | Selected | Enkripsi refresh token Gmail OAuth |

### 2.3 Staff CMS (`apps/cms`)
| Komponen | Teknologi | Status | Catatan |
| --- | --- | --- | --- |
| Framework | Next.js `16.x` (App Router, TypeScript) | Selected | Portal operasional internal Staff |
| Styling & UI | Tailwind CSS `4.x` + `shadcn/ui` | Selected | Antarmuka tabel verifikasi, sengketa, venue, dan payout |
| Data Fetching | `@tanstack/react-query` | Selected | Sinkronisasi state tabel dengan `/v1/cms/*` |

### 2.4 Data Platform & Integrasi Eksternal
| Layanan | Peran di Clarafin | Status |
| --- | --- | --- |
| **Supabase (PostgreSQL, Auth, Storage, Realtime)** | Penyimpanan utama **36 tabel (`erd.md` v2.0)**, autentikasi JWT, penyimpanan dokumen sertifikat & struk OCR, serta realtime chat sesi. | Selected |
| **Redis** | Rate limiting API (termasuk guard `10 req/min` pada `/v1/ai/chat`), cache kuota sementara, dan akselerasi koordinasi booking. | Selected |
| **Xendit API** | Pembuatan tagihan **QRIS** dinamis (batas 15 menit) untuk sesi konsultasi dan langganan Clarafin Pro (`Rp 49.000`) / Unlimited (`Rp 99.000`). | Selected |
| **Google Cloud APIs (OAuth, Gmail API, Google Meet)** | Login Google, izin `gmail.readonly` untuk pindai mutasi/resi 30 hari terakhir, dan pembuatan tautan ruang **Google Meet** sesi Virtual. | Selected |
| **Google Gemini API (`google.golang.org/genai`)** | Ekstraksi teks/suara/OCR struk dan chat *Clarafin AI* via **Strict Two-Pass Pipeline** (`Pass 1` tool/grounding, `Pass 2` `responseSchema`) dengan *helpful hint* netral. | Selected |
| **Firebase Cloud Messaging (FCM)** | Pengiriman push notification (undangan Couple, pengingat jadwal sesi, tagihan jatuh tempo, dan status pencairan). | Selected |
