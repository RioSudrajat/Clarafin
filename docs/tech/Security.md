# Security Architecture & Compliance — Clarafin

| Field | Value |
| --- | --- |
| Project | **Clarafin** |
| Document Version | 3.0 (Rework Aligned) |
| Status | Active |
| Last Updated | 2026-11-01 |

---

## 1. Prinsip Keamanan Utama Clarafin

1. **Zero Bank Credential Policy:** Clarafin tidak pernah meminta atau menyimpan username, password, atau PIN internet banking/m-banking pengguna.
2. **Gmail Read-Only & 30-Day Ephemeral Parsing:**
   - Koneksi email mutasi hanya meminta scope `https://www.googleapis.com/auth/gmail.readonly`.
   - Refresh token OAuth Google dienkripsi menggunakan **AES-256-GCM** (`encrypted_refresh_token BYTEA`) sebelum disimpan di PostgreSQL.
   - Pemindaian hanya membaca email mutasi bank dan resi pembayaran digital dari **30 hari terakhir**. Isi mentah body email tidak pernah disimpan ke database; hanya field terstruktur (`amount`, `merchant_or_note`, `occurred_at`, `external_ref_id`) yang disimpan ke `ai_drafts`.
3. **Per-Session Wallet Consent (`consents`):**
   - Praktisi tidak memiliki akses global ke data keuangan klien.
   - Klien memilih secara eksplisit dompet mana saja (`wallet_ids`) yang diizinkan untuk dilihat praktisi pada setiap sesi.
   - Begitu sesi berakhir (`completed` / `cancelled`) atau klien menekan tombol **Cabut Izin** (`revoked`), akses praktisi ke endpoint ringkasan klien langsung ditutup (`403 FORBIDDEN`).
4. **AI *Helpful Hint* Guardrail, Zero-Trust History, & Idempotency:**
   - Prompt sistem AI mengizinkan ***helpful hint* edukatif yang netral dan tidak berlebihan** tanpa memilihkan tindakan mengikat atau merekomendasikan instrumen/produk spesifik, lalu selalu menutup dengan rekomendasi 1–3 praktisi.
   - Karena chat AI bersifat *ephemeral*, server Go melakukan sanitasi **Zero-Trust** terhadap `session_history` dari client (hanya izinkan role `user`/`model`, tolak `system`/`tool`/`function_response`, batasi panjang pesan & sliding window 8–10 giliran, dan wajib re-query scoped DB tools yang dikunci JWT `user_id`).
   - Mutasi draf dan pemotongan kuota dilindungi `client_mutation_id` dan `client_request_id` idempoten serta rate limit Redis (`10 req/menit`).
5. **Verifikasi Webhook Xendit & Idempotency:**
   - Seluruh callback pembayaran Xendit (`POST /v1/webhooks/xendit`) diverifikasi menggunakan header callback token/signature resmi Xendit dan diproses secara idempoten berdasarkan `xendit_invoice_id`.
6. **Penghapusan Akun & Retensi Arsip Pembayaran 5 Tahun (UU PDP + Kepatuhan Pajak):**
   - Pengguna berhak menghapus akunnya kapan saja selama tidak ada sesi konsultasi yang sedang berjalan.
   - Saat akun dihapus: seluruh data pribadi, dompet, transaksi, anggaran, target, tagihan, draf AI, dan token Gmail dihapus permanen (`ON DELETE CASCADE`).
   - Hanya nilai pembayaran sesi selesai yang disalin ke `deleted_account_payment_archives` menggunakan hash anonim (`SHA-256`) selama **5 tahun** untuk keperluan audit keuangan dan perpajakan.
