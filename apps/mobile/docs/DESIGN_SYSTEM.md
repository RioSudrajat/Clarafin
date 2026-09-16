# Clarafin Design System: Neo-Brutalism × Modern FinTech

Selamat datang di spesifikasi resmi **Clarafin Design System**. Sistem desain ini menggabungkan ketegasan estetika **Neo-Brutalism** (garis luar hitam 2.0px, sudut tegas berradius terstandarisasi, dan bayangan *hard-drop* tanpa blur terproyeksikan ke bawah) dengan keanggunan, keterbacaan tinggi, dan kenyamanan visual dari **Modern FinTech**.

Dokumen ini adalah acuan tunggal (*Single Source of Truth*) untuk seluruh perancangan antarmuka pada aplikasi Clarafin.

---

## 1. Filosofi & Karakter Desain

- **High Contrast & Glanceable Clarity**: Informasi finansial (saldo, budget, jatuh tempo tagihan) harus langsung terbaca dalam sekali pandang. Setiap kontainer, kartu, tombol, dan input wajib memiliki batas luar hitam pekat (`#000000`) 2.0px.
- **Punchy yet Approachable**: Memadukan warna aksen energik **Lime Neon (`#CCFF00`)** dengan latar belakang pastel yang ramah (*Mint*, *Surface Warm*, *Peach*, *Lavender*) serta kedalaman warna gradien brand (*Deep Teal to Lime*).
- **Physicality & Tactility**: Setiap tombol, kartu, dan pill memiliki kesan fisik melalui bayangan tegas terproyeksikan lurus ke bawah (`Offset(0, y)`, `blurRadius: 0`, `spreadRadius: 0`). Tidak menggunakan bayangan miring diagonal atau bayangan kabur (*blurred shadow*).
- **Typography-Driven**: Menggunakan **Quicksand** hanya untuk wordmark merek `clarafin`, dan **Plus Jakarta Sans** untuk seluruh teks antarmuka, label, dan numerik (*geometric, crisp, highly legible*).

---

## 2. Palet Warna (Color Tokens)

### 2.1 Brand & Accent Colors
| Token Name | Hex Code | Visual Preview | Penggunaan |
| :--- | :--- | :---: | :--- |
| `NeoBrutalism.lime` / `AppColors.primary` | `#CCFF00` | 🟨 | **Standar Global Tombol & Aksi Utama**: Tombol *Add New*, *MULAI*, *Jadwalkan*, *Pesan*, FAB `+`, active tab indicator, badge notifikasi aktif, progress bar aktif. |
| `NeoBrutalism.limeNeon` | `#CCFF00` | 🟨 | Aksen neon konsisten untuk highlight visual dan micro-interaksi. |
| `NeoBrutalism.darkTeal` | `#0E6976` / `#0F758A` | 🟦 | Latar kartu Konsultasi Hero Card, anchor awal gradien header. Memberikan kesan terpercaya dan stabil. |
| `NeoBrutalism.mint` | `#E5F9E0` | 🟩 | Kartu banner *Expert Help*, background promo sekunder, badge tag individu. |
| `NeoBrutalism.surfaceWarm` | `#FCF9F8` | 🟫 | Kartu kontainer budget & card netral hangat. |
| `NeoBrutalism.coral` | `#FFDAD6` | 🟥 | Aksen peringatan / pengeluaran hiburan. |
| `AppColors.primaryLight` | `#EFFCC7` | 🟨 | Background kartu *Add New* Wallet / Goal, kartu pastel sekunder. |

### 2.2 Brand Gradient Token
```dart
static const LinearGradient brandGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    Color(0xFF0F758A), // Deep teal
    Color(0xFF198696), // Medium cyan-teal
    Color(0xFF8AD830), // Olive-lime midtone
    Color(0xFFBFFF00), // Bright Lime Green (right edge)
  ],
  stops: [0.0, 0.20, 0.55, 0.90],
);
```
- **Arah**: Horizontal lurus (`centerLeft` &rarr; `centerRight`).
- **Tujuan**: Memastikan sisi kanan atas header (area lonceng notifikasi, avatar, atau tombol filter) selalu menyala terang dengan warna hijau neon di seluruh screen (Home, Consult, Wallet, Budget), tanpa terpengaruh oleh tinggi kontainer maupun efek collapsing scroll.

### 2.3 Neutral & Contrast Colors
| Token Name | Hex Code | Visual Preview | Penggunaan |
| :--- | :--- | :---: | :--- |
| `NeoBrutalism.borderBlack` | `#000000` | ⬛ | Garis pembatas seluruh komponen, border kartu, border tombol, bayangan drop shadow (100% opacity). |
| `NeoBrutalism.dark` | `#111827` | ⬛ | Teks judul utama, nominal saldo, teks heading h1/h2/h3. |
| `NeoBrutalism.textMuted` | `#6B7280` | 🔘 | Teks sekunder, keterangan tanggal, subjudul. |
| `Colors.white` | `#FFFFFF` | ⬜ | Latar kanvas utama (*White Sheet*), background card standar, pill tidak aktif. |
| `AppColors.background` | `#F8F9FA` | ⬜ | Latar belakang default halaman netral. |

### 2.4 Semantic Colors
| Token Name | Hex Code | Penggunaan |
| :--- | :--- | :--- |
| `AppColors.success` | `#10B981` | PnL positif ("Hari ini +Rp..."), tren naik, status berhasil, lunas. |
| `AppColors.error` | `#DC2626` | PnL negatif, pengeluaran berlebih, status jatuh tempo, hapus akun. |
| `AppColors.warning` | `#F59E0B` | Peringatan budget menipis, tagihan mendekati jatuh tempo. |
| `AppColors.info` | `#3B82F6` | Info sinkronisasi akun otomatis, status terjadwal. |

---

## 3. Sistem Tipografi (Typography)

Seluruh teks antarmuka diwajibkan menggunakan **Plus Jakarta Sans** (Google Fonts).

| Level | Size | Weight | Letter Spacing | Penggunaan |
| :--- | :--- | :--- | :--- | :--- |
| **Brand Wordmark** | 26px | 800 (Bold) | -0.5px | Hanya untuk teks logo `clarafin` di Top Bar (Font: Quicksand) |
| **Display Nominal** | 30px | 900 (Black) | -1.4px | Nominal saldo utama pada Total Balance Card & Donut Chart Center |
| **Display Collapsed** | 16.5px | 900 (Black) | -0.8px | Nominal saldo saat sticky card colapse |
| **Hero Title** | 22px | 900 (Black) | -0.6px | Judul kartu hero ("Atur uangmu bareng ahlinya") |
| **Page / Section Header** | 18px | 800 (ExtraBold) | -0.3px | Judul halaman/bagian ("Daftar Konsultan", "Your Wallets", "Layanan") |
| **Card Header** | 16px | 700 / 800 | 0.0px | Judul di dalam kartu ("BCA Utama", "Quick Consult", "Food & Drink") |
| **Body Primary** | 14px | 700 / 900 | 0.0px | Nama transaksi, item layanan, nama konsultan |
| **Body Regular** | 12px | 500 (Medium) | 0.0px | Subjudul deskripsi, keterangan tanggal, keterangan sesi |
| **Button Label** | 12px - 13px | 800 / 900 | 0.2px - 0.5px | Tombol *MULAI*, *Jadwalkan*, *Add New*, *Login*, *Pesan* |
| **Micro Label / Tag** | 10px - 11px | 700 / 800 | 0.4px | Tag sertifikasi "CFP®", "5+ Thn", "Due in 1 days", status akun |

---

## 4. Struktur Bentuk, Garis & Bayangan (Borders & Shadows)

### 4.1 Border Standard
- **Width**: `2.0px` solid black (`#000000`) wajib di seluruh komponen Neo-Brutalism (kartu, tombol, pill, dialog, sheet, bottom nav).
- **Micro Width**: `1.5px` khusus untuk tombol aksi mikro (*Sort by Value*, micro action icon).

### 4.2 Hard Drop Shadow
- Menggunakan `BoxShadow` dengan `blurRadius: 0` dan `spreadRadius: 0` tanpa translusensi (`Colors.black`).
- **Arah Proyeksi**: Wajib vertikal ke bawah lurus (`Offset(0, y)`). Dilarang menggunakan bayangan diagonal miring seperti `Offset(4, 4)` atau `Offset(3, 3)`.
- **Card Shadow**: `Offset(0, 4)` untuk card utama/hero, `Offset(0, 3)` untuk card grid / list reguler.
- **Button / Pill Shadow**: `Offset(0, 2)` (Default button), `Offset(0, 1.5)` (Micro button).
- **Active / Pressed State**: Menghilangkan bayangan (`Offset(0, 0)`) dan mentranslasikan widget ke bawah (`Transform.translate(offset: Offset(0, 2))`) untuk sensasi taktil mekanik penekanan tombol.

### 4.3 Radius Tokens
- `NeoBrutalism.radiusSm`: `12.0px` (Input textfield, tombol aksi kecil, pill tab indicator)
- `NeoBrutalism.radiusMd`: `16.0px` (Sub-wallet pill, modal card kecil, segmented capsule)
- `NeoBrutalism.radiusLg`: `20.0px` (Card list, modal bottom sheet container)
- `NeoBrutalism.radiusXl`: `24.0px` (Hero card, Budget hero, Wallet grid card, Bottom nav)
- `NeoBrutalism.radiusBoundary`: `28.0px` (Lengkungan kanvas putih pemisah header gradien)
- `NeoBrutalism.radiusPill`: `9999.0px` (Tombol pill stadium, filter pills, badge notifikasi)

---

## 5. Arsitektur Komponen Utama

### 5.1 Pinned Header & Curved White Canvas Transition
Setiap halaman utama (Home, Consult, Wallet, Budget) menggunakan pola arsitektur **Pinned Header**:
```dart
Column(
  children: [
    // 1. Header dengan latar NeoBrutalism.brandGradient
    GradientHeaderWidget(...),
    
    // 2. Kanvas Putih yang memuat list scrollable
    Expanded(
      child: Container(
        color: Colors.white,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [...],
        ),
      ),
    ),
  ],
)
```
- **Batas Lengkung Kanvas**: Garis pembatas radius 28px dengan border 2.0px hitam pekat digambar tepat di bawah konten header, menyambung langsung ke kanvas putih di bawahnya.
- **Zero Bleed Rule**: Kontainer induk di balik transisi lengkung wajib dilapisi `NeoBrutalism.brandGradient` agar sudut lengkung transparan tidak menampilkan warna biru/teal patah.

### 5.2 Unified Segmented Capsule Tabs
- Digunakan untuk navigasi sub-halaman (misal: *Goals | Budget | Bills* pada Budget Screen).
- Menggunakan kontainer kapsul tunggal berborder 2.0px hitam, shadow `Offset(0, 2)`, dan background putih.
- Indikator aktif berupa slider berlatar **Lime Neon (`#CCFF00`)** dengan border 2.0px hitam dan bayangan `Offset(0, 1.5)`, beranimasi halus via `AnimatedPositioned` (200ms `Curves.easeInOut`).

### 5.3 Button & CTA Standards
1. **Primary Button (Lime Neon Action)**:
   - Background: `NeoBrutalism.lime` (`#CCFF00`)
   - Border: 2.0px hitam pekat
   - Shadow: `Offset(0, 3)` atau `Offset(0, 2)`
   - Teks: Plus Jakarta Sans 800/900 warna hitam pekat (`#000000`).
2. **Secondary / Outline Button**:
   - Background: `Colors.white`
   - Border: 2.0px hitam pekat
   - Shadow: `Offset(0, 2)`
   - Teks: Plus Jakarta Sans 800 warna hitam pekat.
3. **Micro Tactile Button**:
   - Contoh: Tombol `Sort by Value` di Wallet, tombol mini filter.
   - Border: 1.5px hitam pekat, Shadow: `Offset(0, 1.5)`.
4. **"Add New" Card Pattern**:
   - Background: `#EFFCC7` (Pastel Lime)
   - Circle button: `#CCFF00` (Lime Neon) 46×46px dengan icon `+` hitam
   - Border: 2.0px hitam pekat, Shadow: `Offset(0, 3)`.

### 5.4 Horizontal Filter Pills Pattern
- List filter horizontal dibungkus dengan `SingleChildScrollView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none)`.
- Padding vertikal minimal 4-6px agar border 2.0px dan drop shadow tidak terpotong tepi viewport.
- State Aktif: Background `#CCFF00`, border 2.0px, shadow 2.0px.
- State Inaktif: Background `Colors.white`, border 2.0px, shadow 2.0px.

### 5.5 Form & Input Textfield Pattern
- Border: 2.0px solid black pada kondisi default maupun focused (dilarang menggunakan border tipis abu-abu).
- Hard shadow: `Offset(0, 2)` tanpa blur.
- Background: `Colors.white` atau `#F8F9FA`.
- Typography: Plus Jakarta Sans 600/700 dengan placeholder warna `#9CA3AF`.

### 5.6 Modal & Bottom Sheet Pattern
- Background kanvas: `Colors.white` dengan rounded corner atas 28.0px.
- Garis tepi atas: 2.0px solid black.
- Drag handle pill: Lebar 44px, tinggi 5px, warna `#000000` atau abu-abu tebal berborder.
- Sticky Bottom Action Bar: Tombol aksi utama `#CCFF00` dengan border 2.0px dan shadow vertikal.

---

## 6. Standar Kualitas Kode (Zero Warnings, Modular)

- **Max 200 Baris per File**: Setiap screen hanya bertindak sebagai *orchestrator*. Komponen sub-bagian wajib diekstrak ke folder `presentation/widgets/`.
- **Feature-First Architecture**: Seluruh aset, model domain, provider state, dan widget dikelompokkan berdasarkan feature (`features/<feature_name>/`).
- **State Management**: Seluruh mutasi state lokal dan data tiruan dikelola melalui **Riverpod StateNotifier / Notifier**. Dilarang menempatkan kalkulasi bisnis kompleks langsung di dalam `build()` method widget.
- **Zero Linter Warning**: Setiap kode wajib lulus `flutter analyze` dengan 0 warning dan 0 error sebelum dinyatakan selesai.
