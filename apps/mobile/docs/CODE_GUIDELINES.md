# Clarafin Code Guidelines & Engineering Best Practices

Panduan arsitektur dan kualitas kode untuk pengembangan aplikasi Flutter **Clarafin**. Panduan ini wajib dipatuhi oleh seluruh developer dan agen AI untuk memastikan aplikasi dapat berskala (*scalable*), mudah di-maintain, bebas regresi, dan memiliki performa tinggi (60/120 FPS).

---

## 1. Prinsip Utama: Feature-First Clean Architecture

Struktur folder proyek diatur berdasarkan fitur (*Feature-First*), bukan type-first:

```
lib/
├── core/                         # Fondasi yang dipakai di seluruh aplikasi
│   ├── constants/                # Konstanta global (storage keys, regex, dsb.)
│   ├── institutions/             # Registry & widget logo institusi terpadu
│   ├── models/                   # Model entitas bersama (User, Wallet, Tx)
│   ├── providers/                # Provider reaktif global (Auth, Wallet, PnL)
│   ├── theme/                    # Design tokens (Colors, Typography, Decorations)
│   └── utils/                    # Helper formatters (Currency, Date, Math)
├── features/                     # Fitur-fitur aplikasi
│   ├── <feature_name>/
│   │   ├── domain/               # Model data khusus fitur & contracts
│   │   └── presentation/         # Tampilan UI
│   │       ├── screens/          # Halaman utama (HANYA ORCHESTRATOR)
│   │       └── widgets/          # Komponen modular, isolated, & reusable
├── router/                       # Routing (GoRouter)
└── shared/                       # Widget umum (Buttons, Inputs, Dialogs)
```

### Aturan Emas Ukuran File (Max 200-250 Baris)
1. **Screen Hanya Sebagai Orchestrator**: File screen di bawah `screens/` **tidak boleh berisi implementasi widget detail**. Tugas file screen hanyalah menyusun layout makro (`Scaffold`, `CustomScrollView`, `SliverPersistentHeader`, `Column`, `ListView`) dan memanggil widget modular dari folder `widgets/`.
2. **Pecah Jika Melebihi 200 Baris**: Jika suatu file widget mulai mendekati 200 baris, segera identifikasi sub-komponen yang dapat diekstraksi ke file terpisah di folder `widgets/`.

---

## 2. State Management Best Practices (Riverpod 2.x)

1. **Separasi Penuh Logika Bisnis dari UI**:
   - Dilarang keras menempatkan kalkulasi finansial berat (seperti kalkulasi PnL harian, filtering riwayat tanggal, konversi kurs) di dalam fungsi `build()` widget.
   - Pindahkan seluruh kalkulasi ke Riverpod `Provider`, `NotifierProvider`, atau domain model terpisah.
2. **Hindari Unnecessary Rebuilds**:
   - Gunakan `select` jika widget hanya membutuhkan 1 properti spesifik dari model besar:
     ```dart
     // ✅ BAIK: Widget hanya me-rebuild saat userName berubah
     final userName = ref.watch(userProvider.select((u) => u.name));
     
     // ❌ BURUK: Widget me-rebuild untuk setiap perubahan balance/email
     final user = ref.watch(userProvider);
     ```
3. **Penyimpanan State Lokal**:
   - State yang hanya relevan dengan animasi atau interaksi lokal (misal: `_isExpanded`, `_obscureBalance`, `PageController`) tetap menggunakan `StatefulWidget` / `ConsumerStatefulWidget` lokal agar tidak mengotori global state tree.

---

## 3. Optimasi Performa & Memori (Flutter Best Practices)

1. **Wajib `const` Constructor**:
   - Selalu gunakan `const` untuk widget, padding, edge insets, text styles, dan dekorasi statis.
   - Ini mencegah alokasi memori berulang (*garbage collection churn*) saat widget tree di-rebuild.
2. **Lifecycle Management untuk Controller & Timer**:
   - Semua `TextEditingController`, `PageController`, `ScrollController`, `AnimationController`, dan `Timer` **wajib di-dispose** di metode `dispose()` atau didaftarkan pada `ref.onDispose()`.
3. **List Virtualization**:
   - Gunakan `ListView.builder` atau `SliverList.builder` daripada `SingleChildScrollView` + `Column` jika jumlah item dinamis/panjang.
4. **Hero & Scroll Animations**:
   - Hindari membuat `State` baru di dalam header delegate `build()`.
   - Gunakan interpolasi matematis murni (`lerpDouble`, interval progress clamp) di dalam `SliverPersistentHeaderDelegate` agar scrolling 60/120 FPS tanpa frame drop.

---

## 4. Standar Styling & Design Tokens

1. **Dilarang Hardcoded Styles yang Tidak Standar**:
   - Gunakan token resmi dari `NeoBrutalism` (`NeoBrutalism.lime`, `NeoBrutalism.border()`, `NeoBrutalism.shadow()`) dan `AppColors`.
   - Gunakan `AppTypography` atau `Plus Jakarta Sans` untuk font teks.
2. **Konsistensi Neo-Brutalism**:
   - Garis tepi wajib 2px hitam (`Border.all(color: Colors.black, width: 2)`).
   - Bayangan wajib tanpa blur (`blurRadius: 0`, offset `yOffset: 2` hingga `4`).
3. **Konsistensi Logo Institusi**:
   - Semua logo bank, e-wallet, dan instrumen investasi wajib mengambil aset dari `InstitutionRegistry` terpadu agar visual di seluruh layar (Home, Wallet, Tambah Wallet) seragam dan tidak kontras.

---

## 5. Checklist Sebelum Commit / Pull Request

- [ ] `dart analyze lib/` bersih tanpa error maupun warning.
- [ ] Tidak ada file `presentation/screens/` yang melebihi 250 baris.
- [ ] Logika kalkulasi data dipisahkan ke dalam provider/domain.
- [ ] Tidak ada memory leak (semua controller/timer memiliki `dispose`).
- [ ] Perubahan diuji langsung pada perangkat / emulator dengan Hot Reload.
