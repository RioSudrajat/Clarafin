# Rancangan Clarafin

| Field | Value |
| --- | --- |
| Produk | Clarafin |
| Status | Keputusan terkunci, 6 Oktober 2026 |
| Pemakaian | Sumber untuk membangun launch konsultasi |

Dokumen HaloFin di `docs/` tetap sebagai arsip. Kalau ada benturan, folder `docs-rework-clarafin/` ini yang menang untuk pekerjaan baru. Agen yang masuk ke folder ini membaca `AGENTS.md` lebih dulu.

## Urutan baca

1. [01-keputusan.md](./01-keputusan.md) — yang sudah dikunci, dan yang sengaja ditunda
2. [02-katalog.md](./02-katalog.md) — tier, paket, harga awal, CMS
3. [03-sesi-dan-uang.md](./03-sesi-dan-uang.md) — mesin status sesi, bayar, refund, pencairan
4. [04-ai-dan-data-klien.md](./04-ai-dan-data-klien.md) — batas asisten, tracker, Gmail, izin, hapus akun
5. [05-layar.md](./05-layar.md) — layar klien, praktisi, dan staf, serta layar Flutter yang dipakai ulang
6. [06-sistem.md](./06-sistem.md) — layanan, data, dan irisan pembangunan

## Launch

Launch selesai kalau satu klien sandbox bisa membayar sesi lewat QRIS, praktisi yang sama melihat sesi itu setelah disetujui admin, menulis catatan penutup, dan pencairan terjadwal. Tracker dan AI ikut dalam launch, dengan batas yang tertulis di dokumen 04.
