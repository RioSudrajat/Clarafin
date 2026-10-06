# AGENTS.md — docs-rework-clarafin

Folder ini adalah sumber kebenaran untuk membangun Clarafin sebagai marketplace konsultasi keuangan ritel. Baca folder ini sebelum menulis kode, mengubah navigasi, atau merancang API. Kalau isinya bentrok dengan `docs/` (arsip HaloFin, Maret 2026), folder ini yang dipakai.

## Apa yang sedang dikerjakan

Perancangan sudah dikunci pada 6 Oktober 2026. Yang ada di folder ini adalah dokumen rancangan, belum implementasi.

Aplikasi yang hidup di repo masih prototipe Flutter di `apps/mobile`: data di memori, tanpa backend. Jangan lanjutkan arah lama yang menaruh saldo sebagai beranda dan menunda booking sampai urutan terakhir.

Pekerjaan berikut, berurutan, tertulis di `06-sistem.md`:

1. Auth, profil, tanggal lahir, dan katalog dari database.
2. Lamaran praktisi dan persetujuan staf.
3. Hold slot, QRIS, webhook, sesi lunas, Google Meet untuk virtual.
4. Hadir, catatan penutup wajib, payout, dan refund.
5. Asisten AI dengan kuota dan batas jawaban.
6. Dompet, transaksi, dan izin catatan per sesi.
7. Couple: dua akun, bayar setelah undangan diterima.
8. Komplain, ulasan, sematan, dan Pro.

Irisan berhenti kalau kondisi "selesai kalau" di tabel itu benar di sandbox. Goals, budget, tagihan, sync bank, voucher, skor, dan ekspor tidak menghalangi launch.

## Produk dalam satu halaman

Clarafin menjual sesi dengan manusia. Tracker uang gratis: magnet pengguna, dan bahan yang boleh dibawa ke sesi. AI adalah asisten berkuota, bukan konsultan.

Tiga tier dari sheet bisnis: Basic, Medium, Premium. Basic boleh memetakan utang, tidak boleh merestrukturisasi. Harga hanya kombinasi yang tertulis di `02-katalog.md`. Jangan mengarang harga yang selnya kosong di sheet.

Yang berbayar pada launch: sesi, dan Pro Rp49.000 untuk 400 aksi AI selama 30 hari. QRIS saja yang hidup. Virtual account dan e-wallet tidak muncul di checkout sampai fungsi bayarnya selesai.

## Yang tidak boleh dilakukan

- Jangan membuat AI menyusun restrukturisasi utang, runway, rekomendasi produk, atau rencana yang memilih tindakan. AI berhenti, lalu menawarkan 1–3 praktisi. Detail dan contoh ada di `04-ai-dan-data-klien.md`.
- Jangan membuka catatan uang ke praktisi tanpa izin per sesi. Default tertutup.
- Jangan menampilkan nomor, email, atau akun sosial praktisi. Tatap muka hanya di venue CMS. Belum ada venue, jadi tatap muka belum dijual.
- Jangan menghitung bagi hasil dari harga maksimum di sheet. Platform mengambil persen dari harga yang klien bayar. Default 20%, penimpaan staf hanya 10–35%.
- Jangan memakai urutan integrasi di `docs/tech/Backend.md`.
- Jangan menghapus atau menulis ulang dokumen HaloFin di `docs/` hanya karena bentrok. Tambahkan keputusan baru di folder ini.

## Urutan baca

1. `README.md`
2. `01-keputusan.md`
3. `02-katalog.md`
4. `03-sesi-dan-uang.md`
5. `04-ai-dan-data-klien.md`
6. `05-layar.md`
7. `06-sistem.md`

Mesin uang dan sesi ada di `03`. Layar yang dipakai ulang dari `apps/mobile` ada di `05`. Tabel dan service Go ada di `06`.

## Kode yang sudah ada

| Tempat | Peran |
| --- | --- |
| `apps/mobile` | Flutter. Dipakai ulang, bukan dibuang. Nav launch: Konsultan, Cek, Sesi, Uang, Akun |
| `apps/mobile/docs/DESIGN_SYSTEM.md` | Visual. Tetap berlaku untuk UI |
| `apps/mobile/docs/CODE_GUIDELINES.md` | Feature-first, Riverpod, batas ukuran file. Tetap berlaku untuk Dart |
| `apps/cms` | Belum ada. Web staf, Next.js |
| `services/api` | Belum ada. Satu service Go |
| Supabase | Belum ada di repo. Auth, Postgres, Storage |
| Xendit | QRIS dan pencairan, lewat adapter |

Satu aplikasi untuk klien dan praktisi. UI praktisi baru ada setelah status `verified`. CMS hanya untuk staf.

## Kalau rancangan berubah

Ubah dokumen di folder ini dulu, mulai dari `01-keputusan.md` kalau keputusannya bergeser. Jangan menyimpan aturan produk hanya di chat.
