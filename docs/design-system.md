# HaloFin Design System

| Field | Value |
| --- | --- |
| Project | HaloFin |
| Version | 1.0 |
| Status | Active (Source of Truth) |
| Target Surfaces | Mobile (Flutter), Web (Next.js - Admin/Consultant/Landing) |
| Last Updated | 2026-03-11 |

---

## 1. Overview & Design Philosophy

HaloFin adalah platform manajemen keuangan personal dan konsultasi finansial modern. Design system HaloFin dirancang untuk memberikan pengalaman pengguna yang **segar, intuitif, berenergi (energetic), sekaligus memancarkan rasa aman dan percaya diri (trustworthy)**.

### Prinsip Utama Desain

1. **Clarity & Financial Confidence**: Tampilan angka finansial, saldo, dan grafik disajikan bersih dan tidak membingungkan (*cognitive load minimal*).
2. **Modern & High-Contrast Accent**: Memadukan warna netral yang tenang (*off-white/surface clean*) dengan aksen **Bright Lime Green** yang khas, modern, dan memberikan *vibe* generasi fintech masa kini.
3. **Card-Driven & Content Chunking**: Informasi dikelompokkan dalam kartu-kartu (*cards*) dengan *border radius* lembut (20px) dan bayangan tipis (*soft low-elevation shadows*).
4. **Accessible & High-Readability**: Teks di atas warna aksen terang selalu menggunakan kontras tinggi (dark text di atas Lime Green) sesuai standar WCAG AA.
5. **Consistency across Surfaces**: Token desain yang konsisten antara aplikasi mobile Flutter dan portal web Next.js.

---

## 2. Color Palette & Tokens

### 2.1 Brand & Accent Colors

Warna utama HaloFin adalah **Bright Lime Green**, memberikan diferensiasi visual yang kuat dibanding aplikasi finansial tradisional yang biasanya didominasi warna biru atau hijau tua.

| Token | Hex | RGB | Preview | Deskripsi & Penggunaan |
| --- | --- | --- | --- | --- |
| `primary` | `#CCFF00` | `rgb(204, 255, 0)` | 🟩 | Warna brand utama. Digunakan untuk CTA primer, highlight aktif, progress bar aktif. |
| `primaryDark` | `#B3E600` | `rgb(179, 230, 0)` | 🟩 | State hover/pressed pada tombol utama dan border aktif. |
| `primaryLight` | `#E6FF80` | `rgb(230, 255, 128)` | 🟨 | Background badge, highlight ring, tint lembut. |
| `accentBlue` / `accentCyan` | `#B2F5EA` | `rgb(178, 245, 234)` | 🟦 | Aksen sekunder untuk kategori aset tertentu, tag informatif, & AI hints. |

> [!IMPORTANT]
> **Aturan Kontras Warna Utama:**
> Karena `#CCFF00` memiliki luminansi tinggi, teks atau ikon yang berada di atas elemen bertema `primary` **HARUS menggunakan `textPrimary` (`#1A1A1A`)**, BUKAN warna putih (`#FFFFFF`).

---

### 2.2 Neutral & Surface Colors

| Token | Hex | RGB | Deskripsi & Penggunaan |
| --- | --- | --- | --- |
| `background` | `#F8F9FA` | `rgb(248, 249, 250)` | Background default halaman aplikasi (Off-white lembut). |
| `surface` | `#FFFFFF` | `rgb(255, 255, 255)` | Warna dasar kartu, modal bottom sheet, form container, dan app bar. |
| `navBg` | `#FCFEF0` | `rgb(252, 254, 240)` | Background khusus untuk floating / bottom navigation bar dengan sedikit sentuhan tint lime. |
| `divider` | `#E5E7EB` | `rgb(229, 231, 235)` | Garis pemisah tipis antar baris list atau section. |
| `border` | `#D1D5DB` | `rgb(209, 213, 219)` | Garis outline default untuk input field, chip non-aktif, dan card outline. |

---

### 2.3 Typography Colors

| Token | Hex | Kegunaan |
| --- | --- | --- |
| `textPrimary` | `#1A1A1A` | Judul, nominal saldo utama, headline, teks tombol primer (kontras tinggi). |
| `textSecondary` | `#6B7280` | Deskripsi, label sekunder, timestamp, placeholder input, subtitle. |
| `textInverse` | `#FFFFFF` | Teks di atas container gelap, badge merah/error, banner gelap. |

---

### 2.4 Semantic & Feedback Colors

Digunakan untuk memberikan indikasi status keuangan, transaksi, dan peringatan sistem:

| Token | Hex | Penggunaan Finansial & Sistem |
| --- | --- | --- |
| `success` | `#10B981` | Transaksi **Pemasukan (Income)**, status *Paid/Lunas*, verifikasi sukses, saldo aman. |
| `error` | `#EF4444` | Transaksi **Pengeluaran (Expense)**, status *Over Budget*, tagihan jatuh tempo, validasi gagal. |
| `warning` | `#F59E0B` | Peringatan budget mendekati limit (>80%), tagihan mendekati jatuh tempo. |
| `info` | `#3B82F6` | Rekomendasi sistem, tips AI, notifikasi informasi, transfer antar rekening. |

---

## 3. Typography System

HaloFin menggunakan **Manrope** (Google Fonts) sebagai tipografi tunggal untuk seluruh antarmuka. Manrope memiliki bentuk geometris yang modern, angka tabular yang proporsional, serta keterbacaan yang sangat tinggi pada perangkat mobile.

### 3.1 Type Scale Hierarchy

| Style / Token | Size (px) | Weight | Line Height | Penggunaan |
| --- | --- | --- | --- | --- |
| `displayLarge` | 32px | Bold (700) | 40px | Display nominal saldo utama, hero stat dashboard |
| `displayMedium` | 28px | Bold (700) | 36px | Header halaman utama, angka total laporan bulanan |
| `displaySmall` | 24px | Bold (700) | 32px | Section header besar, nilai target tabungan |
| `headlineMedium` | 20px | SemiBold (600) | 28px | Judul card hero, nama profil konsultan |
| `headlineSmall` | 18px | SemiBold (600) | 26px | Sub-section title, modal dialog title |
| `titleLarge` | 16px | SemiBold (600) | 24px | Judul item list, nama kategori transaksi, judul widget |
| `bodyLarge` | 16px | Regular (400) | 24px | Teks paragraf utama, input text pada form |
| `bodyMedium` | 14px | Regular (400) | 20px | Deskripsi item, catatan transaksi, bio singkat |
| `bodySmall` | 12px | Regular (400) | 16px | Tanggal/waktu transaksi, helper text, footnote |
| `labelLarge` | 14px | SemiBold (600) | 20px | Teks tombol (CTA), filter chip aktif, tab title |
| `labelSmall` | 10px | Medium (500) | 14px | Status badge kecil, label bottom navigation icon |

---

## 4. Spacing, Layout & Grid System

HaloFin menerapkan sistem **8-Point Grid** dengan sub-grid 4px untuk penyesuaian detail.

### 4.1 Spacing Scale

| Token | Nilai | Contoh Penggunaan |
| --- | --- | --- |
| `xs` | `4.0px` | Gap antar badge dan icon, padding micro chip |
| `sm` | `8.0px` | Gap antar baris label dan value, margin icon text |
| `md` | `16.0px` | Default padding dalam card, padding input form, item spacing standar |
| `lg` | `24.0px` | Edge margin halaman (kiri & kanan layar), padding section besar |
| `xl` | `32.0px` | Jarak antar section besar, hero spacing |
| `xxl` | `48.0px` | Empty state vertical spacing, margin footer |

### 4.2 Specific Layout Values

```dart
// Dari AppSpacing (Flutter Codebase)
static const double edgeMargin    = 24.0; // Margin kiri-kanan layar
static const double itemSpacing   = 16.0; // Jarak antar item dalam ListView
static const double cardRadius    = 20.0; // Radius kartu utama
static const double buttonRadius  = 12.0; // Radius tombol & input
static const double chipRadius    = 16.0; // Radius filter chip
```

---

## 5. Shape & Corner Radii

HaloFin menggunakan sudut membulat yang bersahabat (*friendly & modern rounded aesthetic*):

| Kategori Elemen | Radius | Token / Class |
| --- | --- | --- |
| **Pill / Badge** | `999px` / `Stadium` | Filter chips penuh, toggle pill, indicator tag |
| **Card Container** | `20px` | `AppSpacing.cardRadius` (Semua card ringkasan, wallet card, goal card) |
| **Filter Chip** | `16px` | `AppSpacing.chipRadius` (Chip kategori, wallet filter) |
| **Button & Input** | `12px` | `AppSpacing.buttonRadius` (Elevated button, text input fields) |
| **Bottom Sheet Modal** | `24px - 32px` (Top) | Modal transaksi baru, filter bottom sheet |

---

## 6. Elevation & Shadows

Efek bayangan dibuat sangat lembut (*subtle & diffuse*) agar antarmuka tidak terasa berat atau kaku.

* **Card Elevation:** `elevation: 2` dengan `shadowColor: Colors.black.withValues(alpha: 0.05)` (atau `0 4px 20px rgba(0, 0, 0, 0.04)` di Web).
* **Floating Bottom Nav:** Bayangan lembut mengambang `shadowColor: Colors.black.withValues(alpha: 0.08)`, `blurRadius: 16`, `offset: (0, 4)`.
* **Button Elevation:** `elevation: 0` (Flat solid modern look) pada primary elevated button, mengandalkan warna `primary` yang kontras.

---

## 7. Component Library & Guidelines

### 7.1 Buttons & Actions

#### Primary Button (`ElevatedButton`)
* **Background:** `AppColors.primary` (`#CCFF00`)
* **Text / Icon Color:** `AppColors.textPrimary` (`#1A1A1A`)
* **Typography:** `labelLarge` (14px / 16px Bold/SemiBold)
* **Padding:** Vertikal `16px` (`md`), Horizontal `24px` (`lg`)
* **Radius:** `12px` (`AppSpacing.buttonRadius`)
* **Elevation:** `0` (Flat solid)

#### Secondary / Outlined Button
* **Background:** Transparent atau `AppColors.surface`
* **Border:** `1.5px solid AppColors.border` (`#D1D5DB`)
* **Text Color:** `AppColors.textPrimary` (`#1A1A1A`)
* **Radius:** `12px`

#### Floating Action / Bottom Nav Action
* Center button bulat atau menonjol untuk "Add Transaction" (+) dengan warna `#CCFF00` dan icon hitam.

---

### 7.2 Navigation Components

#### Floating Bottom Nav (`AppBottomNav`)
* **Container:** Floating bar dengan margin bawah dan samping (`horizontal: 24px, bottom: 16px`).
* **Background:** `AppColors.navBg` (`#FCFEF0`) dengan radius `28px - 32px`.
* **Items (5 menu):**
  1. **Home** (Beranda)
  2. **Budget** (Perencanaan / Budget)
  3. **Add (+)** (Action utama di tengah)
  4. **Consult** (Konsultasi Finansial)
  5. **Wallet** (Dompet & Aset)
* **Active State Indicator:** Lingkaran atau pill warna `primary` (`#CCFF00`) dengan icon hitam.

#### Segmented Tabs (`FinanceTabs`)
* Digunakan pada modul perencanaan (*Goals / Budget / Bills*).
* Container pill dengan background abu terang/surface, tab aktif berlatar putih atau `#CCFF00` dengan font bold.

---

### 7.3 Cards & Data Containers

#### 1. Total Balance Hero Card
* Menampilkan nominal total kekayaan pengguna (`displayLarge`).
* Menampilkan ringkasan portofolio (Kas, Tabungan, Investasi) dan tombol aksi cepat (*Top Up, Transfer, Analytics*).

#### 2. Category Budget & Progress Card
* Menampilkan nama kategori, icon kategori, nominal terpakai vs total limit.
* Menggunakan `ProgressBar` dengan indikator warna dinamis:
  * `< 70%`: `AppColors.primary` atau `success`
  * `70% - 90%`: `AppColors.warning`
  * `> 90% / Over`: `AppColors.error`

#### 3. Interactive Donut Chart (`InteractiveDonutChart`)
* Visualisasi proporsi aset atau pengeluaran.
* Dilengkapi interaksi klik per segmen dengan total saldo di tengah chart.

#### 4. Consultant Profile Card (`ConsultantCard` & `ConsultantMiniProfile`)
* Foto profil/avatar dengan badge verifikasi (`verified_badge`).
* Nama konsultan, rating bintang (contoh: ⭐ 4.9), spesialisasi (*Tax, Investment, Retirement*), harga sesi, dan tombol *Book/Schedule*.

#### 5. Heatmap Calendar (`HeatmapCalendar`)
* Visualisasi intensitas pengeluaran harian sepanjang bulan.
* Menggunakan gradasi warna lime/emerald untuk hari hemat dan merah/orange untuk hari belanja tinggi.

---

### 7.4 Input & Form Controls

#### Text & Number Field (`InputDecorationTheme`)
* **Background:** `AppColors.surface` (Putih).
* **Border:** `1px solid #D1D5DB`, radius `12px`.
* **Focus State:** `2px solid #CCFF00` (Highlight terang).
* **Hint Style:** `bodyMedium` dengan warna `textSecondary` (`#6B7280`).

#### Search Bar (`SearchInput`)
* Input dengan rounded corner (`24px` atau `12px`), icon kaca pembesar di sisi kiri, dan tombol clear (X) di sisi kanan.

#### Filter Chips (`FilterChipWidget`)
* Container pill (`radius 16px`).
* **Non-aktif:** Background abu-abu muda/transparan dengan border `#D1D5DB`, teks `textSecondary`.
* **Aktif:** Background `#CCFF00` atau `#1A1A1A` dengan teks kontras tinggi.

---

### 7.5 State & Feedback Components

1. **Loading State (`state_loading_skeleton`)**:
   * Efek *shimmer* lembut menggunakan base color `#E5E7EB` dan highlight `#F3F4F6`.
2. **Empty State (`state_empty_placeholder`)**:
   * Ilustrasi minimalis bertema monokrom/lime, teks penjelasan jelas, dan tombol call-to-action (contoh: "Tambah Transaksi Pertama").
3. **Error State (`state_error_card`)**:
   * Card berlatar merah muda lembut dengan icon peringatan dan tombol "Coba Lagi" (*Retry*).

---

## 8. Code Implementation Reference (Flutter)

Berikut adalah mapping token desain yang diimplementasikan pada Flutter mobile app:

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  static const Color primary      = Color(0xFFCCFF00); // Bright Lime Green
  static const Color primaryDark  = Color(0xFFB3E600);
  static const Color primaryLight = Color(0xFFE6FF80);
  
  static const Color background   = Color(0xFFF8F9FA); // Off-White
  static const Color surface      = Colors.white;
  static const Color navBg        = Color(0xFFFCFEF0);
  
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textInverse   = Colors.white;
  
  static const Color success    = Color(0xFF10B981);
  static const Color error      = Color(0xFFEF4444);
  static const Color warning    = Color(0xFFF59E0B);
  static const Color info       = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFFB2F5EA);
  
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border  = Color(0xFFD1D5DB);
}
```

```dart
// lib/core/theme/app_spacing.dart
class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
  
  static const double edgeMargin   = 24.0;
  static const double itemSpacing  = 16.0;
  static const double cardRadius   = 20.0;
  static const double buttonRadius = 12.0;
  static const double chipRadius   = 16.0;
}
```

---

## 9. Web / CSS Design Token Equivalence

Untuk aplikasi Web (*Admin*, *Consultant Portal*, *Landing Page*), gunakan variabel CSS berikut:

```css
:root {
  /* Brand Tokens */
  --hf-color-primary: #CCFF00;
  --hf-color-primary-dark: #B3E600;
  --hf-color-primary-light: #E6FF80;
  
  /* Neutral Tokens */
  --hf-color-bg: #F8F9FA;
  --hf-color-surface: #FFFFFF;
  --hf-color-nav-bg: #FCFEF0;
  --hf-color-border: #D1D5DB;
  --hf-color-divider: #E5E7EB;
  
  /* Text Tokens */
  --hf-color-text-primary: #1A1A1A;
  --hf-color-text-secondary: #6B7280;
  --hf-color-text-inverse: #FFFFFF;
  
  /* Semantic Tokens */
  --hf-color-success: #10B981;
  --hf-color-error: #EF4444;
  --hf-color-warning: #F59E0B;
  --hf-color-info: #3B82F6;
  --hf-color-accent-cyan: #B2F5EA;
  
  /* Radii */
  --hf-radius-button: 12px;
  --hf-radius-chip: 16px;
  --hf-radius-card: 20px;
  --hf-radius-full: 9999px;
  
  /* Typography */
  --hf-font-family: 'Manrope', -apple-system, BlinkMacSystemFont, sans-serif;
}
```

---

## 10. Design Checklist for Engineers

Sebelum membuat *Pull Request* atau menyelesaikan slicing halaman baru, pastikan:

- [ ] Menggunakan token dari `AppColors`, `AppSpacing`, dan `AppTypography` (hindari *hardcoded colors* dan *magic numbers*).
- [ ] Teks di atas warna aksen Lime Green (`#CCFF00`) menggunakan warna hitam (`AppColors.textPrimary`), BUKAN putih.
- [ ] Margin horizontal layar konsisten sebesar `AppSpacing.edgeMargin` (24px).
- [ ] Card memiliki radius `20px` dengan bayangan tipis/subtle (`alpha: 0.05`).
- [ ] Komponen form dan input field memiliki border default `#D1D5DB` dan active focus border `#CCFF00`.
- [ ] Mengimplementasikan minimal 3 status: **Loading (Shimmer)**, **Empty State**, dan **Error State** di setiap tampilan daftar data.
