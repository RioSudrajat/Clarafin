# Canonical Glossary — Clarafin

| Field | Value |
| --- | --- |
| Project | Clarafin |
| Document Version | 3.0 (Rework Aligned) |
| Status | Active |
| Last Updated | 2026-11-01 |
| Purpose | Single source of truth untuk istilah domain, status siklus hidup, dan konvensi penamaan lintas produk, frontend, dan backend. |

## Change Summary

| Date | Change |
| --- | --- |
| 2026-11-01 | Diselaraskan penuh dengan `docs-rework-clarafin`: penyatuan nama produk menjadi Clarafin, penambahan istilah katalog (`Basic`, `Medium`, `Premium`), sesi pasangan (`Couple`), kehadiran (`Hadir`), catatan penutup 3 bagian (`ClosingNote`), kuota AI & Pro (`AIUsageLedger`, `ProSubscription`), pemindaian mutasi email (`GmailConnection`), persetujuan dompet per sesi (`SessionConsent`), dan penghapusan akun terarsip (`DeletedAccountPaymentArchive`). Mempertahankan struktur navigasi bawah eksisting (`Home`, `Consult`, `FAB (+)`, `Wallet`, `Budget` + Floating Session). |
| 2026-03-11 | Added domain terms for Budget, Goal, Bill, Notification, Report, DataExport, Currency. |
| 2026-03-09 | Initial canonical glossary. |

---

## 1. Core Domain Objects

| Canonical Term | Definition | Notes |
| --- | --- | --- |
| **User** | Pengguna terdaftar di aplikasi mobile Clarafin (minimal usia 18 tahun, tervalidasi dari tanggal lahir saat registrasi). Seorang User dapat bertindak sebagai Klien, dan jika terverifikasi (`verified`) pada `practitioner_profiles`, juga memiliki mode tampilan Praktisi di aplikasi yang sama. | Semua jumlah uang disimpan dalam satuan **IDR** (`BIGINT`). |
| **Practitioner** (Praktisi / Konsultan) | Tenaga ahli keuangan bersertifikat (`CFP`, `QWP`, `AEPP`, `Brevet Pajak`, atau sertifikasi relevan yang diverifikasi staff CMS) yang membuka layanan konsultasi di Clarafin. | Menggantikan istilah generik yang ambigu; di UI dapat ditampilkan sebagai "Konsultan" atau "Praktisi". |
| **Wallet** (Dompet) | Representasi sumber dana atau aset pengguna (`bank`, `ewallet`, `cash`, `investment`, `other`) yang menyimpan saldo dalam IDR. | Pengguna dapat memilih dompet mana saja yang dibagikan ke Praktisi pada setiap sesi. |
| **Transaction** | Catatan finansial final (`income`, `expense`, `transfer`) yang memengaruhi saldo `Wallet`. | Dapat berasal dari input manual, konfirmasi draf AI, atau konfirmasi draf hasil pindai email mutasi/resi Gmail. |
| **DraftTransaction** (`ai_drafts`) | Rancangan transaksi sementara hasil ekstraksi AI (teks/suara/foto struk) atau pemindaian email mutasi Gmail yang berstatus `pending_review` sebelum dikonfirmasi pengguna. | Tidak memengaruhi saldo `Wallet` sampai statusnya berubah menjadi `confirmed`. |
| **Budget** | Batas pengeluaran bulanan pengguna, baik secara total bulanan (`Total Budget`) maupun per kategori pengeluaran (`Category Budget`). | Ditampilkan pada tab `Budget` di layar Perencanaan Keuangan (`/budget`). |
| **Goal** (Target Tabungan) | Target dana spesifik yang ingin dicapai pengguna beserta nominal terkumpul (`saved_amount`), target nominal (`target_amount`), dan tenggat waktu (`target_date`). | Ditampilkan pada sub-tab `Goals` di layar `/budget`. |
| **Bill** (Tagihan) | Kewajiban pembayaran berkala atau satu kali beserta tanggal jatuh tempo (`due_date`) dan status lunas (`is_paid`). | Ditampilkan pada sub-tab `Bills` di layar `/budget`. |
| **CatalogPackage** | Paket layanan konsultasi terstandarisasi berdasarkan tingkat kedalaman masalah (**Basic**, **Medium**, **Premium**), kanal (**Chat**, **Virtual**, **Tatap Muka**), dan jumlah peserta (**1 Orang**, **Couple**). | Lihat matriks harga di `PRD.md`. |
| **ConsultationSession** (`sessions`) | Satu pesanan layanan konsultasi antara Klien (dan opsional pasangan/partner pada sesi `Couple`) dengan Praktisi pada jadwal dan kanal yang disepakati. | Menyimpan snapshot harga, potongan komisi (`platform_cut_pct`), status kehadiran, dan tenggat pencairan. |
| **SessionConsent** (`consents`) | Izin akses baca (*read-only*) per sesi yang diberikan Klien kepada Praktisi atas satu atau beberapa `Wallet` terpilih (`wallet_ids`). | Berlaku hanya selama sesi aktif dan otomatis berakhir (`expired`) saat sesi selesai atau dicabut (`revoked`) oleh Klien. |
| **ClosingNote** (`session_notes`) | Catatan penutup wajib 3 bagian yang ditulis Praktisi maksimal **24 jam** setelah sesi berakhir: (1) *Inti Masalah*, (2) *3 Langkah 30 Hari ke Depan*, (3) *1 Aturan Jangan Dilakukan*. | Menjadi syarat pencairan dana sesi (`completed` -> `payout_ready_at` +48 jam). |
| **SessionComplaint** (`session_complaints`) | Keluhan resmi yang diajukan Klien sebelum pencairan dana, yang menahan pencairan (`disputed`) hingga diputuskan oleh Staff di CMS. | Keputusan staff: `release_to_practitioner`, `full_refund`, atau `partial_refund`. |
| **AIUsageLedger** | Catatan pemakaian kuota aksi AI pengguna per bulan (`reserved -> success / failed`). Kuota gratis adalah **40 aksi/bulan** (reset tiap tanggal 1 pukul 00:00 WIB). | Reservasi atomik memakai `client_request_id`; aksi yang gagal karena error sistem dikompensasi dan tidak memotong kuota. |
| **ProSubscription** | Langganan berbayar **Clarafin Pro (`Rp 49.000` / 30 hari, 400 aksi)** atau **Clarafin Unlimited (`Rp 99.000` / 30 hari, tanpa batas aksi)** untuk kuota AI & Gmail Auto-Sync. | Kuota Pro yang tidak terpakai hangus saat 30 hari berakhir; pembatasan rate limit tetap berlaku. |
| **GmailConnection** | Koneksi OAuth *read-only* (`gmail.readonly`) ke akun Gmail pengguna untuk memindai email mutasi bank dan resi pembayaran digital dari **30 hari terakhir**. | Token disimpan terenkripsi `AES-256-GCM`; isi mentah email tidak pernah disimpan ke database. |
| **Venue** | Lokasi fisik terkurasi yang dikelola Staff di CMS sebagai tempat pelaksanaan sesi **Tatap Muka**. | Kanal Tatap Muka tidak dapat dipilih di suatu kota bila belum ada Venue aktif di kota tersebut. |

---

## 2. Canonical Status Values

### 2.1 Consultation Session Status (`sessions.status`)
| Status | Meaning |
| --- | --- |
| `waiting_partner` | Khusus sesi `Couple`: Klien pembuat sesi telah memilih jadwal, menunggu pasangan menerima undangan (batas **24 jam**). |
| `waiting_payment` | Menunggu pembayaran QRIS via Xendit (**15 menit** sejak tagihan dibuat / sejak pasangan menerima undangan). |
| `scheduled` | Pembayaran lunas; jadwal sesi telah dikunci dan menunggu waktu pelaksanaan. |
| `ongoing` | Sesi sedang berlangsung (telah melewati waktu mulai). |
| `awaiting_notes` | Waktu sesi selesai dan kehadiran Klien valid; menunggu Praktisi mengirim `ClosingNote` 3 bagian (batas **24 jam**). |
| `completed` | Praktisi telah mengirim `ClosingNote`; masa tunggu pencairan **48 jam** dimulai (`payout_ready_at`). |
| `disputed` | Klien mengajukan keluhan sebelum dana cair; pencairan ditahan menunggu keputusan Staff CMS. |
| `cancelled` | Sesi dibatalkan (tidak dibayar dalam 15 menit, dibatalkan Klien/Praktisi, atau kadaluarsa undangan pasangan). |
| `no_show_client` | Klien tidak menekan tombol `Hadir` hingga **15 menit** setelah sesi dimulai (Praktisi menerima **50%**, Klien refund **50%**). |
| `no_show_practitioner` | Praktisi tidak hadir hingga **15 menit** setelah sesi dimulai (Klien refund **100%**). |

### 2.2 AI & Gmail Draft Status (`ai_drafts.status`)
| Status | Meaning |
| --- | --- |
| `pending_review` | Draf transaksi baru dari AI (teks/suara/foto struk) atau pemindaian email Gmail yang menunggu konfirmasi pengguna. |
| `confirmed` | Pengguna telah menyetujui draf; transaksi final telah dibuat di tabel `transactions` dan saldo `Wallet` telah diperbarui. |
| `discarded` | Pengguna menolak atau membatalkan draf; tidak memengaruhi saldo `Wallet`. |

### 2.3 Session Wallet Consent Status (`consents.status`)
| Status | Meaning |
| --- | --- |
| `active` | Izin akses dompet terpilih sedang aktif untuk sesi terkait. |
| `revoked` | Pengguna mencabut izin akses secara manual sebelum sesi berakhir; akses Praktisi langsung tertutup detik itu juga. |
| `expired` | Sesi telah berakhir (`completed` / `cancelled`); akses Praktisi otomatis tertutup. |

### 2.4 Practitioner Verification Status (`practitioner_profiles.status`)
| Status | Meaning |
| --- | --- |
| `pending` | Pengajuan menjadi praktisi sedang ditinjau oleh Staff di CMS. |
| `verified` | Sertifikasi telah diverifikasi Staff; mode Praktisi terbuka di aplikasi mobile untuk pengguna tersebut. |
| `suspended` | Akun praktisi dibekukan sementara atau permanen oleh Staff karena pelanggaran atau ketidakpatuhan. |

---

## 3. Navigation & Delivery Terms

| Term | Definition |
| --- | --- |
| **Bottom Navigation (Locked Override)** | Navigasi utama aplikasi mobile yang terdiri dari 4 tab + tombol aksi tengah: **`Home` (`/home`)**, **`Consult` (`/consult`)**, **`FAB (+)`** (Quick Action / Input Transaksi), **`Wallet` (`/wallet`)**, dan **`Budget` (`/budget` — mencakup sub-tab *Goals*, *Budget*, *Bills*)**, dilengkapi **Floating Session Button** di kanan bawah layar `Home` menuju **`/session`**. |
| **`mobile_frontend`** | Fase delivery aktif saat ini di mana seluruh layar, navigasi, komponen Neo-Brutalism, dan state lokal di `apps/mobile` diselesaikan dan dikunci terlebih dahulu sebelum integrasi backend. |
| **`mobile_backend_integration`** | Fase delivery berikutnya setelah `mobile_frontend` dikunci, mencakup pembuatan Go API (`services/api`), skema Supabase Postgres (`docs/tech/erd.md`), autentikasi riil, Xendit QRIS, Gmail OAuth, dan Gemini AI. |
| **`cms_staff`** | Aplikasi web internal (`apps/cms` berbasis Next.js) khusus Staff Clarafin untuk memverifikasi praktisi, mengatur override komisi (`10%–35%`), mengelola `venues`, memutus `session_complaints`, dan mengeksekusi pencairan dana (`payouts`). |
