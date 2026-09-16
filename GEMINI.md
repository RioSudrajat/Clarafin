# Antigravity Agent Guidelines & Skill Decision Matrix

Dokumen ini adalah panduan operasional utama untuk agen AI Antigravity pada repositori **Halofin**. Agen wajib membaca dan mematuhi panduan ini pada setiap sesi dan eksekusi task.

---

## 1. Core Skill Directory & Routing

Semua skill kustom workspace tersimpan di dalam `.agents/skills/`. Agen harus mengaktifkan skill yang relevan berdasarkan konteks pekerjaan sebelum menulis kode atau mendesain antarmuka.

### Decision Matrix: Kapan Menggunakan Skill Tertentu?

| Tipe Pekerjaan / Permintaan User | Skill Utama yang Wajib Diaktifkan | Skill Pendukung / Synergies |
| :--- | :--- | :--- |
| **Membuat / Redesign UI Flutter** | `antislop-ui`, `antislop` | `gpt-taste`, `high-end-visual-design`, `apps/mobile/docs/DESIGN_SYSTEM.md` |
| **Slicing Mockup / Gambar Referensi ke Kode** | `image-to-code`, `antislop-ui` | `antislop-layoutmobile`, `full-output-enforcement` |
| **Refactor / Upgrade Halaman yang Sudah Ada** | `redesign-existing-projects` | `antislop`, `apps/mobile/docs/CODE_GUIDELINES.md` |
| **Penyesuaian Responsivitas & Layout Mobile** | `antislop-layoutmobile` | `antislop-human` (touch targets 44px+) |
| **Aksesibilitas, Kontras, & Ergonomi Pengguna** | `antislop-human` | `flutter_a11y_agent` (subagent) |
| **Menulis / Memperbaiki Teks, Label, Microcopy** | `antislop-copywriting` | `antislop` (Filter klise AI) |
| **Membersihkan Komentar Kode dari AI Slop** | `antislop-code` | `apps/mobile/docs/CODE_GUIDELINES.md` |
| **Implementasi Kode Lengkap Tanpa Truncation** | `full-output-enforcement` | Wajib aktif saat generate file utuh / refactor besar |
| **Eksplorasi Gaya Neo-Brutalisme / Industrial** | `industrial-brutalist-ui` | `apps/mobile/docs/DESIGN_SYSTEM.md` |
| **Integrasi & Prompting Google Stitch** | `stitch-design-taste` | `StitchMCP` tools |
| **Pembuatan Brand Kit & Token Warna Baru** | `brandkit` | `minimalist-ui` |

---

## 2. Aturan Konflik & Hierarki Desain (Precedence Rules)

Jika terjadi perbedaan arahan gaya antara skill umum dengan desain spesifik proyek:
1. **Aturan Tertinggi**: `apps/mobile/docs/DESIGN_SYSTEM.md` (Spesifikasi resmi Halofin Neo-Brutalism: 2px black border, hard shadow 4px/2px tanpa blur, font Plus Jakarta Sans, palet Lime `#9ADC09`/`#CCFF00`, Teal `#0F758A`, kanvas putih).
2. **Aturan Kualitas Arsitektur**: `apps/mobile/docs/CODE_GUIDELINES.md` (Feature-First, max 200 baris per screen/widget, pemisahan kalkulasi bisnis ke Riverpod Notifier, zero warning).
3. **Filter Anti-Slop**: `antislop` & `antislop-ui` (Melarang efek generik AI tanpa fungsi: glow ungu/biru neon sembarangan, icon generic bintang/petir, layout template AI yang membosankan).
4. **Kelengkapan Output**: `full-output-enforcement` (Dilarang menggunakan `// TODO`, `// rest of code`, atau kode terpotong).

---

<!-- antislop:start -->
## antislop
For UI, copy, people, mobile layout, or code comments work, read `.agents/skills/antislop/SKILL.md` (core) and then the skill for the task:
- UI / visual: `.agents/skills/antislop-ui/SKILL.md`
- Copy & text: `.agents/skills/antislop-copywriting/SKILL.md`
- People: `.agents/skills/antislop-human/SKILL.md`
- Mobile / responsive: `.agents/skills/antislop-layoutmobile/SKILL.md`
- Code comments: `.agents/skills/antislop-code/SKILL.md`
Before starting, ask the user when antislop applies: during the work, or after it is done.
<!-- antislop:end -->
