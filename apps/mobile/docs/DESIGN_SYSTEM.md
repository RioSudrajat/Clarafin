# Clarafin Design System: Neo-Brutalism × Modern FinTech

Selamat datang di spesifikasi resmi **Clarafin Design System**. Sistem desain ini menggabungkan ketegasan estetika **Neo-Brutalism** (garis luar hitam 2px, sudut tegas berradius, dan bayangan *hard-drop* tanpa blur) dengan keanggunan serta keterbacaan tinggi dari **Modern FinTech**.

---

## 1. Filosofi & Karakter Desain

- **High Contrast & Clarity**: Informasi finansial harus langsung terbaca dalam sekali pandang (*glanceable*). Setiap kontainer utama memiliki garis pembatas hitam pekat (`#000000`) 2px.
- **Punchy yet Approachable**: Menggabungkan warna aksen energik (*Clarafin Lime*) dengan latar belakang pastel yang ramah (*Mint*, *Surface Warm*, *Off-White*) serta warna teal tua yang stabil dan profesional (*Deep Teal*).
- **Physicality & Tactility**: Setiap tombol, kartu, dan pill memiliki kesan fisik melalui bayangan tegas terproyeksikan ke bawah (`Offset(0, y)`, `blurRadius: 0`).
- **Typography-Driven**: Menggunakan **Quicksand** untuk identitas merek (*friendly, rounded, human*) dan **Plus Jakarta Sans** untuk seluruh teks antarmuka, label, dan numerik (*geometric, crisp, highly legible*).

---

## 2. Palet Warna (Color Tokens)

### 2.1 Brand & Accent Colors
| Token Name | Hex Code | Visual Preview | Penggunaan |
| :--- | :--- | :---: | :--- |
| `NeoBrutalism.lime` / `AppColors.primary` | `#9ADC09` | 🟩 | Warna utama brand Clarafin, logo squircle, tombol aksi utama (*MULAI*, *Simpan*), progress bar terpakai, badge notifikasi. |
| `NeoBrutalism.limeNeon` | `#CCFF00` | 🟨 | Aksen neon untuk highlight sekunder / visual contrast. |
| `NeoBrutalism.darkTeal` | `#0E6976` | 🟦 | Latar kartu Konsultasi Hero Card, bagian atas gradien header. Memberikan kesan terpercaya dan aman. |
| `NeoBrutalism.mint` | `#E5F9E0` | 🟩 | Kartu banner *Expert Help*, background promo sekunder. |
| `NeoBrutalism.surfaceWarm` | `#FCF9F8` | 🟫 | Kartu *Keuangan Bulan Ini* / Budget container. Hangat dan tidak silau. |
| `NeoBrutalism.coral` | `#FFDAD6` | 🟥 | Aksen peringatan / kategori hiburan & pengeluaran tertentu. |

### 2.2 Neutral & Contrast Colors
| Token Name | Hex Code | Visual Preview | Penggunaan |
| :--- | :--- | :---: | :--- |
| `NeoBrutalism.borderBlack` | `#000000` | ⬛ | Garis luar semua kartu, tombol, divider tegas, bayangan drop shadow (100% opacity). |
| `NeoBrutalism.dark` | `#111827` | ⬛ | Teks judul utama, nominal saldo, teks heading h1/h2/h3. |
| `NeoBrutalism.textMuted` | `#6B7280` | 🔘 | Teks sekunder, keterangan tanggal, subjudul. |
| `Colors.white` | `#FFFFFF` | ⬜ | Latar belakang kanvas, pill saldo, search button, card surface. |
| `AppColors.background` | `#F8F9FA` | ⬜ | Latar belakang default halaman. |

### 2.3 Semantic Colors
| Token Name | Hex Code | Penggunaan |
| :--- | :--- | :--- |
| `AppColors.success` | `#10B981` | Indikator PnL positif ("Hari ini +Rp..."), tren naik, status berhasil. |
| `AppColors.error` | `#DC2626` | Indikator PnL negatif ("Hari ini -Rp..."), tren turun, validasi error. |
| `AppColors.warning` | `#F59E0B` | Status peringatan budget hampir habis, notifikasi tertunda. |

---

## 3. Sistem Tipografi (Typography)

Seluruh teks antarmuka diwajibkan menggunakan **Plus Jakarta Sans** (Google Fonts).

| Level | Size | Weight | Line Height | Letter Spacing | Penggunaan |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Brand Wordmark** | 26px | 800 (Bold) | 1.0 | -0.5px | Hanya untuk teks `clarafin` di Top Bar (Font: Quicksand) |
| **Display Nominal** | 30px | 900 (Black) | 1.1 | -1.4px | Nominal saldo utama pada Total Balance Card |
| **Display Collapsed** | 16.5px | 900 (Black) | 1.1 | -0.8px | Nominal saldo saat sticky card colapse |
| **Hero Title** | 22px | 900 (Black) | 1.15 | -0.6px | Judul kartu hero konsultasi ("Atur uangmu bareng ahlinya") |
| **Section Title** | 18px | 700 (Bold) | 1.2 | 0.0px | Judul section ("Keuangan Bulan Ini", "Recent Activity") |
| **Card Header** | 16px | 700 (Bold) | 1.2 | 0.0px | Judul di dalam kartu ("Budget", "Edit Nama") |
| **Body Primary** | 14px | 900 / 700 | 1.3 | 0.0px | Judul transaksi, teks banner expert help |
| **Body Regular** | 12px | 500 (Medium) | 1.25 | 0.0px | Subjudul kartu hero, teks keterangan budget |
| **Label Bold** | 11px | 800 / 700 | 1.2 | 0.4px | Label "TOTAL BALANCE", tombol "MULAI", "Portfolio" |
| **Micro Label** | 10px | 700 (Bold) | 1.1 | 0.5px | Indikator "Hari ini", tag "EXPERT HELP", nama sub-wallet pill |

---

## 4. Struktur Bentuk, Garis & Bayangan (Borders & Shadows)

### 4.1 Border Standard
- **Width**: `2.0px` (Wajib di seluruh komponen Neo-Brutalism).
- **Color**: `Colors.black` (`#000000`).

### 4.2 Hard Drop Shadow
- Menggunakan `BoxShadow` dengan `blurRadius: 0` dan `spreadRadius: 0`.
- **Card Shadow**: `yOffset: 4.0` (Expanded), `yOffset: 2.0` (Collapsed / Small Card).
- **Pill / Button Shadow**: `yOffset: 2.0` (Default), `yOffset: 1.5` (Micro Button).
- **Hover / Active State**: Menghilangkan bayangan dan menggeser posisi elemen ke bawah (`translate(0, 2)`) untuk sensasi mekanikal penekanan tombol.

### 4.3 Radius Tokens
- `Radius.sm`: `12.0px` (Input textfield, tombol aksi kecil)
- `Radius.md`: `16.0px` (Sub-wallet pill, button container)
- `Radius.lg`: `20.0px` (Dialog, bottom sheet header)
- `Radius.xl`: `24.0px` (Hero card, Budget card, Expert banner, Service grid card)
- `Radius.curveBoundary`: `28.0px` (Lengkungan pembatas antara header teal gradient dan kanvas putih)
- `Radius.pill`: `9999.0px` (Tombol pill, badge PnL hari ini, action indicator)
- `Radius.circle`: `BoxShape.circle` (Avatar, floating action bot, icon category circle)

---

## 5. Standar Komponen UI

### 5.1 Hero Header Card (Collapsible)
- **Expanded Height**: 198px
- **Collapsed Height**: 64px
- **Curtain Animation**: Menggunakan interpolasi kurva `Curves.easeIn` untuk efek tirai yang tergulung ke atas (`translateY: -32px`, `opacity: 0.0`) saat card mulai menciut.
- **Anchored Elements**: Teks greeting `Hi, [Name]` dan nominal `Rp [Saldo]` memiliki koordinat absolut terlabuh sehingga tidak menghilang saat di-scroll melainkan bertransisi ukuran font dan posisi secara halus.

### 5.2 Sub-Wallet Pill
- Menggunakan `Container` dengan padding `12px horizontal, 7px vertical`, border hitam 2px, radius 16px, dan shadow 2px.
- Menampilkan logo institusi (BCA, GoPay, dsb.) di dalam badge lingkaran berdiameter 26px di sisi kiri, diikuti nama akun dan saldo tebal di sisi kanan.

### 5.3 Bottom Navigation Bar
- Berbentuk kotak kokoh dengan sudut tumpul (`BorderRadius.circular(24)`), garis tepi hitam 2px, dan bayangan drop-shadow 4px. Tidak menggunakan lengkungan setengah lingkaran penuh (*half-circle stadium*).
