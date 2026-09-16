# Clarafin Frontend Master Task & Implementation Plan (`task.md`)

Dokumen ini adalah rencana kerja komprehensif (*Master Execution Plan*) untuk penyelesaian seluruh antarmuka frontend aplikasi **Clarafin** hingga beres dan siap rilis, dengan kepatuhan 100% terhadap **Clarafin Design System: Neo-Brutalism × Modern FinTech** (`DESIGN_SYSTEM.md`) dan **Code Guidelines** (`CODE_GUIDELINES.md`).

> [!IMPORTANT]
> **Batasan Lingkup Kerja**:
> - **Frontend Saja**: Seluruh logika aplikasi, alur navigasi, dan interaktivitas dikelola menggunakan **Riverpod StateNotifier** dengan data tiruan (*mock data*) realistis dan reaktif.
> - **Tidak Menyentuh Backend**: Belum melibatkan integrasi server API, database eksternal, atau network endpoints riil.

---

## 1. Matriks Status Seluruh Screen Antarmuka

| No | Feature / Domain | Screen / Modal | Route Path | Status Saat Ini | Kebutuhan Tindakan |
| :---: | :--- | :--- | :--- | :---: | :--- |
| **A** | **Halaman Utama (Main Shell)** | | | | |
| 1 | Home | `HomeScreen` | `/home` | ✅ **Selesai** | Gradien disamakan dengan Consult, tombol neon lime global, hero collapsible. |
| 2 | Consult | `ConsultListScreen` | `/consult` | ✅ **Selesai** | Header fixed, Match Expert banner di bawah konsultan 1, card konsultan Neo-Brutalism. |
| 3 | Wallet | `WalletScreen` | `/wallet` | ✅ **Selesai** | Header fixed, Donut Chart interaktif (rotasi diperbaiki), sort tactile, grid card. |
| 4 | Budget | `BudgetScreen` (Goals, Budget, Bills) | `/budget` | ✅ **Selesai** | Unified segmented capsule tab dengan lime neon sliding indicator, card Neo-Brutalism. |
| 5 | Bottom Nav | `AppBottomNav` | Shell Widget | ✅ **Selesai** | Squircle floating box, tombol FAB `+` neon lime (`#CCFF00`). |
| **B** | **Fitur / Layanan yang Masih Hilang (Belum Dibuat)** | | | | |
| 6 | Notifikasi | `NotificationsScreen` | `/notifications` | ✅ **Selesai** | Screen notifikasi lengkap (tab filter kategori, mark as read, unread count badge, card notifikasi Neo-Brutalisme). |
| 7 | Consult Filter | `ConsultFilterBottomSheet` | Modal Sheet | ✅ **Selesai** | Modal sheet Neo-Brutalisme (rentang tarif slider, rating minimal, metode konsultasi, spesialisasi, filter dot indicator di header). |
| 8 | Layanan: Financial Score | `FinancialHealthScreen` | `/score` | ✅ **Selesai** | Skor Kesehatan Keuangan (82/100, 4 rasio bento card, rekomendasi aksi deep-link). |
| 9 | Layanan: Kupon & Voucher | `VoucherScreen` | `/vouchers` | ✅ **Selesai** | Katalog voucher promo Neo-Brutalisme, filter tab, salin kode & deep-link "Pakai" ke `/consult`. |
| 10 | Ekspor Data | `ExportDataScreen` | `/export` | ✅ **Selesai** | Screen konfigurasi ekspor lengkap (periode waktu, format PDF/Excel/CSV, preview scope, feedback). |
| 11 | Profile: Edit Profil | `EditProfileScreen` | `/profile/edit` | ✅ **Selesai** | Form ganti nama lengkap (sinkron dengan `userNameProvider`), avatar, no HP, email. |
| 12 | Profile: Keamanan | `SecuritySettingsScreen` | `/profile/security` | ✅ **Selesai** | Switch aktivasi Biometrik/Fingerprint, form ganti 6-digit PIN modal, info perangkat terhubung. |
| 13 | Profile: Notifikasi | `NotificationSettingsScreen` | `/profile/notifications` | ✅ **Selesai** | Switch preferensi notifikasi (transaksi, jadwal, tagihan, promo eksklusif). |
| 14 | Profile: Bantuan & CS | `HelpSupportScreen` | `/profile/support` | ✅ **Selesai** | Accordion FAQ interaktif & kartu CS WhatsApp 24/7. |
| **C** | **Halaman Eksisting yang Perlu Redesign Neo-Brutalism** | | | | |
| 15 | Profile Utama | `ProfileScreen` | `/profile` | ✅ **Selesai** | Redesign total: User card hero, bento metrics (sesi, goals, wallet), menu grouped, dialog konfirmasi logout. |
| 16 | Consult Detail | `ConsultDetailScreen` | `/consult/:id` | ⚠️ **Perlu Redesign** | Perlu distandarisasi ke Neo-Brutalism (rating card, badge spesialisasi, jadwal picker, sticky booking bar). |
| 17 | Booking Step 1 | `BookingServiceScreen` | `/booking/:id/service` | ⚠️ **Perlu Redesign** | Masih kode lama 529 baris, paket layanan perlu diubah ke Neo-Brutalist cards. |
| 18 | Booking Step 2 | `BookingTimeScreen` | `/booking/:id/time` | ⚠️ **Perlu Redesign** | Kalender & time slot chips perlu border 2px dan drop shadow Neo-Brutalism. |
| 19 | Booking Step 3 | `BookingPreConsultationScreen` | `/booking/:id/pre-consult` | ⚠️ **Perlu Redesign** | Form intake konsultasi perlu input field Neo-Brutalism. |
| 20 | Booking Step 4 | `BookingPaymentScreen` | `/booking/:id/payment` | ⚠️ **Perlu Redesign** | Pilihan metode bayar (QRIS, VA, E-Wallet) dan ringkasan pembayaran Neo-Brutalism. |
| 21 | Consult Chat | `ConsultChatScreen` | `/consult/chat` | ⚠️ **Perlu Redesign** | Chat room interaktif dengan konsultan finansial. |
| 22 | Match Expert | `MatchExpertScreen` | `/match-expert` | ⚠️ **Perlu Review** | Sempurnakan konsistensi token neon lime `#CCFF00` dan shadow vertikal. |
| 23 | Wallet Detail | `WalletDetailScreen` | `/wallet/:id` | ⚠️ **Perlu Redesign** | Halaman detail akun finansial (riwayat transaksi spesifik akun, kartu saldo, sinkronisasi). |
| 24 | Add Wallet (Instansi) | `AddWalletInstitutionScreen` | `/wallet/add` | ⚠️ **Perlu Redesign** | Pemilihan bank & e-wallet dengan card Neo-Brutalism. |
| 25 | Add Wallet (Manual) | `ManualWalletEntryScreen` | Modal / Route | ⚠️ **Perlu Redesign** | Form input saldo dan nama akun manual. |
| 26 | Add/Edit Budget | `AddEditBudgetScreen` | `/budget/add`, `/budget/edit/:id` | ⚠️ **Perlu Redesign** | Form pembuatan/edit budget kategori. |
| 27 | Add/Edit Goal | `AddEditGoalScreen` | `/goal/add`, `/goal/edit/:id` | ⚠️ **Perlu Redesign** | Form pembuatan target tabungan baru. |
| 28 | Goal Detail | `GoalDetailScreen` | `/goal/:id` | ⚠️ **Perlu Redesign** | Breakdown target tabungan, proyeksi, riwayat setor. |
| 29 | Add/Edit Bill | `AddEditBillScreen` | `/bill/add`, `/bill/edit/:id` | ⚠️ **Perlu Redesign** | Form pembuatan/edit tagihan berkala. |
| 30 | Transaksi Entry | `TransactionEntryScreen` | `/transaction/entry` | ⚠️ **Perlu Redesign** | Fast input pengeluaran/pemasukan/transfer dengan keypad numerik Neo-Brutalism. |
| 31 | Riwayat Transaksi | `TransactionHistoryScreen` | `/transaction/history` | ⚠️ **Perlu Redesign** | Pencarian, filter rentang tanggal, filter kategori, list transaksi. |
| 32 | Transaksi Sukses | `TransactionSuccessScreen` | `/transaction/success` | ⚠️ **Perlu Redesign** | Struk bukti transaksi bergaya Neo-Brutalism dengan share CTA. |
| 33 | AI Draft Review | `AiDraftReviewScreen` | `/draft/review` | ⚠️ **Perlu Redesign** | Konfirmasi hasil scan struk via AI OCR. |
| 34 | Financial Report | `ReportDashboardScreen` | `/reporting` | ⚠️ **Perlu Redesign** | Laporan bulanan, chart distribusi pengeluaran, perbandingan pemasukan. |
| 35 | Session Branch | `BranchSessionScreen` | `/session` | ⚠️ **Perlu Redesign** | Hub percakapan asisten finansial AI Clarafin. |
| 36 | AI Chat | `AiChatScreen` | `/ai-chat` | ⚠️ **Perlu Redesign** | Chatbot copilot finansial cerdas. |
| 37 | Auth Login | `AuthLoginScreen` | `/login` | ✅ **Selesai** | Form login Neo-Brutalism, background gradien biru satu warna, logo polos tanpa wrapper. |
| 38 | Auth Register | `AuthRegisterScreen` | `/register` | ✅ **Selesai** | Form registrasi Neo-Brutalism dengan validasi terms checkbox, logo polos. |
| 39 | Onboarding Welcome | `OnboardingWelcomeScreen` | `/onboarding` | ✅ **Selesai** | Splash/Carousel 3 benefit, capsule indicator, tombol neon lime, modular < 200 baris. |
| 40 | Onboarding Wallet | `OnboardingWalletSetupScreen` | `/onboarding/wallet-setup` | ✅ **Selesai** | Step 1/2 header, 4 tactile wallet cards, tactile inputs, modular < 200 baris. |
| 41 | Onboarding Goal | `OnboardingSetGoalScreen` | `/onboarding/goal` | ✅ **Selesai** | Step 2/2 header, 4 tactile goal cards, target mulai badges, navigasi ke /home. |

---

## 2. Rincian Fitur & Screen yang Wajib Dibuat Baru (Missing Screens)

### 2.1 Notifications Center (`/notifications`)
- **Trigger**: Icon lonceng pada `HomeTopAppBar` (`home_top_app_bar.dart`).
- **Komponen Utama**:
  - Pinned Header: Judul "Notifikasi", tombol "Tandai Dibaca", badge total belum dibaca.
  - Filter Tabs: `Semua`, `Transaksi`, `Konsultasi`, `Promo`, `Sistem` (Neo-Brutalist pills).
  - Notification Cards: Card putih border 2px, shadow 2px, unread indicator dot lime neon (`#CCFF00`), icon kategori, waktu relatif ("10m yang lalu"), deskripsi, dan tombol aksi langsung (misal: "Lihat Transaksi", "Masuk Sesi Chat").
  - Empty State: Ilustrasi Notion-style "Tidak ada notifikasi baru".
- **Local State (`notifications_provider.dart`)**:
  - `List<NotificationModel>` dengan state `isRead`, timestamp, kategori, targetRoute.
  - Notifier method: `markAsRead(id)`, `markAllAsRead()`, `deleteNotification(id)`.

### 2.2 Consultant Filter Bottom Sheet Modal (`ConsultFilterBottomSheet`)
- **Trigger**: Icon filter lingkaran pada `ConsultGradientHeader` (`consult_list_screen.dart`).
- **Komponen Utama**:
  - White Bottom Sheet Neo-Brutalism dengan border atas 2px dan drag handle pill.
  - Filter Spesialisasi: Multi-select pills (`Pajak & Bisnis`, `Investasi & Portofolio`, `Restrukturisasi Utang`, `Dana Pensiun`, `Keuangan Keluarga`, `Cashflow & Budgeting`).
  - Rentang Tarif per Sesi: `RangeSlider` Neo-Brutalism dari Rp 100.000 s/d Rp 1.500.000 dengan indikator nominal tebal.
  - Rating Minimal: Selector pill (`Semua`, `⭐ 4.5+`, `⭐ 4.8+`).
  - Jam Terbang Pengalaman: Selector pill (`Semua`, `>3 Thn`, `>5 Thn`, `>10 Thn`).
  - Sticky Actions: Tombol "Reset" (outline putih) dan "Terapkan Filter" (Lime Neon `#CCFF00`).
- **Local State (`consultant_filter_provider.dart`)**:
  - `ConsultantFilterState` dengan properti query, spesialisasi, minPrice, maxPrice, minRating, minYearsExp.
  - Menyambung langsung ke `filteredConsultantsProvider` di `consult_list_screen.dart`.

### 2.3 Profile & Settings Suite
- **A. Main Profile Dashboard (`/profile`)**:
  - Hero Card Profil: Foto avatar dengan border 2px, nama pengguna, email, status tier pengguna (misal: "Clarafin Pro Member" badge lime).
  - Summary Bento Cards: Total Sesi Konsultasi Selesai, Target Aktif, Akun Terhubung.
  - Menu Settings Group:
    - **Akun**: Edit Profil (`/profile/edit`), Kategori Pengeluaran Favorit.
    - **Keamanan**: Biometrik / PIN (`/profile/security`), Perangkat Terhubung.
    - **Preferensi**: Notifikasi (`/profile/notifications`), Bahasa & Mata Uang.
    - **Bantuan**: FAQ & Bantuan (`/profile/support`), Kebijakan Privasi, Syarat & Ketentuan.
    - **Akun Aksi**: Tombol *Keluar* (Card border 2px aksen merah pastel `#FFDAD6`).
- **B. Edit Profil (`/profile/edit`)**:
  - Ganti nama tampilan (sinkron dengan `userNameProvider`), no telepon, foto avatar selector.
- **C. Keamanan & PIN (`/profile/security`)**:
  - Switch toggle biometrik Face ID / Fingerprint, form ganti 6-digit PIN transaksi.
- **D. Pengaturan Notifikasi (`/profile/notifications`)**:
  - Toggle switch Neo-Brutalism untuk notifikasi transaksi, pengingat tagihan, promo konseling.
- **E. Pusat Bantuan & CS (`/profile/support`)**:
  - FAQ kategori, card langsung hubungi Konsultan Support Clarafin.

### 2.4 Layanan Finansial Terdedikasi (Services Flow)
- **A. Financial Health Score (`/score`)**:
  - Saat ini icon `Score` di Home grid salah me-redirect ke `/budget`.
  - **Screen Baru**: Menampilkan Skor Kesehatan Finansial pengguna (misal: **82/100 - "Sangat Sehat"**).
  - 4 Pilar Analisis Finansial (Bento Grid):
    1. *Rasio Dana Darurat*: 6/6 bulan pengeluaran (Aman).
    2. *Rasio Cicilan & Utang*: 18% dari pendapatan (<30% Sehat).
    3. *Rasio Menabung & Investasi*: 25% dari pendapatan (>20% Unggul).
    4. *Proteksi Asuransi*: Tercover BPJS & Asuransi Jiwa.
  - Rekomendasi Aksi: CTA langsung hubungi konsultan atau tambah tabungan.
- **B. Voucher & Promo Katalog (`/vouchers`)**:
  - Daftar kupon diskon konsultasi (misal: "Diskon 50% Sesi Pertama", "Cashback Investasi Bibit").
  - Tombol aksi "Salin Kode" atau "Gunakan Sekarang" yang langsung mengisi kupon saat booking.
- **C. Deep-link Kategori Konseling**:
  - Icon `Individu`, `Pasangan`, `Keluarga`, `UMKM` di grid Home kini mengarahkan ke `/consult?category=...` dan otomatis memfilter daftar konsultan sesuai kategori yang dipilih.

### 2.5 Data Export Suite (`/export`)
- **Menggantikan `PlaceholderScreen`**.
- Pilihan Rentang Waktu: Bulan Ini, 3 Bulan Terakhir, 1 Tahun, Kustom Tanggal.
- Pilihan Format: Dokumen PDF Ringkasan Keuangan, Excel Spreadsheet (.xlsx), CSV Transaksi.
- Pilihan Pos: Sertakan riwayat tagihan, sertakan mutasi wallet, sertakan catatan budget.
- Tombol aksi utama: "Unduh Laporan" & "Kirim ke Email" (simulasi mock loading & snackbar sukses).

---

## 3. Rencana Eksekusi Bertahap (Step-by-Step Phases)

### 🔹 Phase 1: High-Impact Missing Entrypoints (✅ Selesai & Diverifikasi)
> Menuntaskan seluruh navigasi dan modal yang saat ini belum ada atau buntu di halaman utama.
1. **Task 1.1**: ✅ `NotificationsScreen` (`/notifications`), model `NotificationModel`, provider `notifications_provider.dart`, dan terhubung ke icon lonceng di `home_top_app_bar.dart`.
2. **Task 1.2**: ✅ `ConsultFilterBottomSheet`, provider `consultant_filter_provider.dart`, badge dot neon lime, dan terhubung ke icon filter di `consult_list_screen.dart`.
3. **Task 1.3**: ✅ Redesign menyeluruh `ProfileScreen` (`/profile`) dengan arsitektur Neo-Brutalism, user card, bento summary, dan menu navigasi.
4. **Task 1.4**: ✅ Sub-halaman profile lengkap: `EditProfileScreen` (`/profile/edit`), `SecuritySettingsScreen` (`/profile/security`), `NotificationSettingsScreen` (`/profile/notifications`), dan `HelpSupportScreen` (`/profile/support`).
5. **Verifikasi**: ✅ Teruji di emulator, navigasi bolak-balik mulus, `analyze_files` 0 issue.

### 🔹 Phase 2: Layanan & Dedicated Service Flows (✅ Selesai & Diverifikasi)
> Menghubungkan seluruh ikon di Services Grid Home & All Services Bottom Sheet ke halaman fungsional.
1. **Task 2.1**: ✅ Buat `FinancialHealthScreen` (`/score`), provider `financial_health_provider.dart`, diagram skor, 4 bento rasio, dan hubungkan ikon "Score" di Home grid.
2. **Task 2.2**: ✅ Buat `VoucherScreen` (`/vouchers`), model promo voucher, tombol salin kode, dan hubungkan ikon "Kupon" di Home.
3. **Task 2.3**: ✅ Perbaiki routing kategori konseling (`Individu`, `Pasangan`, `Keluarga`, `UMKM`) agar memfilter `ConsultListScreen` secara reaktif via URL parameter / state.
4. **Task 2.4**: ✅ Ubah `PlaceholderScreen(title: 'Data Export')` menjadi `ExportDataScreen` (`/export`) fungsional bergaya Neo-Brutalism.
5. **Verifikasi**: ✅ Teruji di emulator, seluruh rute berfungsi, `analyze_files` 0 issue.

### 🔹 Phase 3: Booking & Consultation Flow Modernization (✅ Selesai & Diverifikasi)
> Menyempurnakan alur konsultasi dari detail konsultan hingga pembayaran dan chat.
1. **Task 3.1**: ✅ Audit dan polish `ConsultDetailScreen` (`/consult/:id`) sesuai token `DESIGN_SYSTEM.md` (2.0px black border, no blur).
2. **Task 3.2**: ✅ Redesign `BookingServiceScreen` (Step 1): Pemilihan paket layanan (Quick Consult / Deep Dive / Comprehensive) dengan kartu Neo-Brutalisme (modular < 200 baris per file).
3. **Task 3.3**: ✅ Redesign `BookingTimeScreen` (Step 2): Kalender Neo-Brutalism, slot waktu, durasi.
4. **Task 3.4**: ✅ Redesign `BookingPreConsultationScreen` (Step 3): Form intake kebutuhan konsultasi & uploader dokumen.
5. **Task 3.5**: ✅ Redesign `BookingPaymentScreen` (Step 4): Pemilihan metode pembayaran (QRIS, VA, E-Wallet) dan ringkasan pembayaran Neo-Brutalism.
6. **Task 3.6**: ✅ Redesign `ConsultChatScreen` (`/consult/chat`): Ruang obrolan dengan konsultan keuangan, bubble pesan Neo-Brutalism, typing indicator, quick replies interaktif.
7. **Verifikasi**: ✅ Teruji end-to-end di emulator dari katalog -> detail -> Step 1 -> Step 2 -> Step 3 -> Step 4 -> Chat Room dengan simulasi chat otomatis, 0 issue analyze.

### 🔹 Phase 4: Financial Management & Transactions
> Menyempurnakan pencatatan transaksi, detail wallet, dan pengelolaan budget/goals/bills.
1. **Task 4.1**: ⏸️ `TransactionEntryScreen` (`/transaction/entry`): *Dilewati sementara menunggu prompt & instruksi spesifik dari user.*
2. **Task 4.2**: ✅ Redesign `TransactionHistoryScreen` (`/transaction/history`): Search bar stadium, filter waktu, grouping per tanggal, modular < 200 baris, filter bottom sheet & dynamic summary.
3. **Task 4.3**: ✅ Redesign `TransactionSuccessScreen` (`/transaction/success`): Resi struk Neo-Brutalism dengan share card & animasi bouncy checkmark terjaga.
4. **Task 4.4**: ✅ Redesign `WalletDetailScreen` (`/wallet/:id`): Detail akun kartu, statistik saldo, mutasi per wallet, dialog hapus dompet, modular < 200 baris.
5. **Task 4.5**: ✅ Redesign `AddWalletInstitutionScreen` (`/wallet/add`) & `ManualWalletEntryScreen` (`/wallet/manual`): Pencarian institusi, bottom sheet sinkronisasi otomatis vs manual, form input dompet manual responsif, modular < 200 baris.
6. **Task 4.6**: ✅ Redesign Form Sub-halaman Budget & Goals: `AddEditBudgetScreen`, `AddEditGoalScreen`, `GoalDetailScreen`, `AddEditBillScreen` (Modular < 200 baris, verified di emulator).

### 🔹 Phase 5: Auth, Onboarding & Analytics
> Memastikan pintu masuk aplikasi dan pelaporan analitik selaras dengan gaya visual baru.
1. **Task 5.1**: ✅ Redesign `AuthLoginScreen` (`/login`) & `AuthRegisterScreen` (`/register`) bergaya Neo-Brutalism dengan background gradien biru/teal satu warna dan logo transparan tanpa background container (Modular < 200 baris, verified di emulator).
2. **Task 5.2**: ✅ Redesign Onboarding Flow: `OnboardingWelcomeScreen`, `OnboardingWalletSetupScreen`, `OnboardingSetGoalScreen` (Modular < 200 baris, verified di emulator).
3. **Task 5.3**: Redesign `ReportDashboardScreen` (`/reporting`): Visualisasi grafik PnL, pie chart alokasi pengeluaran, tab Ikhtisar/Pengeluaran/Pemasukan.
4. **Task 5.4**: Redesign AI Assistant Sessions: `BranchSessionScreen` (`/session`) & `AiChatScreen` (`/ai-chat`).

### 🔹 Phase 6: Final End-to-End Quality Gate
1. **Task 6.1**: Pengujian seluruh rute GoRouter (`app_router.dart`) tanpa ada rute broken atau redirect salah.
2. **Task 6.2**: Pengujian `flutter analyze` menyeluruh pada seluruh direktori `lib/` (target: **0 warnings, 0 errors**).
3. **Task 6.3**: Verifikasi konsistensi bayangan `Offset(0, y)`, border 2.0px, dan warna neon lime `#CCFF00` di setiap screen.

---

## 4. Standar Implementasi Teknis (Code & State Standards)

- **Routing Blueprint**: Seluruh screen terdaftar di `lib/router/app_router.dart` dengan path yang bersih dan typed arguments.
- **Local State Providers**:
  - `notificationsProvider`: StateNotifier mengelola list notifikasi lokal.
  - `consultantFilterProvider`: StateNotifier kriteria filter konsultan.
  - `financialHealthProvider`: Provider data metrik skor finansial.
  - `vouchersProvider`: Provider daftar kode promo & diskon.
  - `userProfileProvider`: StateNotifier nama, email, PIN, dan biometrik pengguna.
- **Komponen Modular**: Wajib mengekstrak widget ke subfolder `widgets/` jika screen mendekati atau melebihi 200 baris.
- **Aset & Ikon**: Menggunakan Plus Jakarta Sans (Google Fonts) dan icon vector / doodle yang telah terdaftar.
