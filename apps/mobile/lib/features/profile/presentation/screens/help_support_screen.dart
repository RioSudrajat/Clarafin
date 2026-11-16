import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'Bagaimana cara menjadwalkan sesi konsultasi?',
      'answer':
          'Buka tab "Consult", pilih konsultan keuangan yang sesuai dengan kebutuhan Anda, tentukan jenis paket layanan, pilih jadwal tanggal dan jam, lalu selesaikan pembayaran.',
    },
    {
      'question': 'Apakah data finansial dan akun bank saya aman?',
      'answer':
          'Sangat aman. Clarafin menggunakan enkripsi end-to-end standar perbankan (AES-256) dan mematuhi regulasi privasi data keuangan Indonesia.',
    },
    {
      'question': 'Bagaimana cara menambahkan dompet atau akun baru?',
      'answer':
          'Buka tab "Wallet", tekan tombol "+ Tambah Akun" di pojok kanan atas atau card Tambah Baru di akhir daftar akun, lalu pilih institusi perbankan Anda.',
    },
    {
      'question': 'Apa perbedaan konsultasi Online vs Tatap Muka?',
      'answer':
          'Konsultasi Online berlangsung melalui obrolan/video call terenkripsi di aplikasi Clarafin, sedangkan Tatap Muka dilakukan di lokasi kantor mitra konsultan yang disepakati.',
    },
    {
      'question': 'Bagaimana cara membatalkan atau menjadwal ulang sesi?',
      'answer':
          'Buka sesi aktif Anda di menu Sesi, pilih "Ajukan Reschedule" maksimal 6 jam sebelum sesi dimulai untuk memilih slot waktu baru tanpa biaya penalti.',
    },
  ];

  int? _expandedIndex;

  void _showSupportTicketSheet(BuildContext context) {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.black, width: 2.0),
              left: BorderSide(color: Colors.black, width: 2.0),
              right: BorderSide(color: Colors.black, width: 2.0),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: NeoBrutalism.primary,
                      shape: BoxShape.circle,
                      border: NeoBrutalism.border(width: 1.5),
                    ),
                    child: const Icon(Icons.support_agent_rounded, size: 20, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hubungi Tim Bantuan Clarafin',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tim operasional kami akan menanggapi tiket Anda dalam waktu kurang dari 15 menit.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: NeoBrutalism.textMuted,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Topik / Subjek',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: NeoBrutalism.border(width: 1.8),
                  boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                ),
                child: TextField(
                  controller: subjectController,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'Misal: Kendala pembayaran sesi atau sync dompet',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Detail Pesan & Keluhan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: NeoBrutalism.border(width: 1.8),
                  boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                ),
                child: TextField(
                  controller: messageController,
                  maxLines: 4,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    hintText: 'Ceritakan kendala yang Anda alami secara rinci...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  final subj = subjectController.text.trim();
                  final msg = messageController.text.trim();
                  if (subj.isEmpty || msg.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Mohon lengkapi subjek dan detail pesan terlebih dahulu.',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: NeoBrutalism.dark,
                      ),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tiket bantuan berhasil dikirim! Tim kami akan segera menghubungi Anda.',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: NeoBrutalism.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: NeoBrutalism.primary,
                    borderRadius: BorderRadius.circular(14),
                    border: NeoBrutalism.border(width: 2.0),
                    boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Kirim Tiket Bantuan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F758A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: NeoBrutalism.brandGradient,
        ),
        child: Column(
          children: [
            // Pinned Neo-Brutalist Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: NeoBrutalism.border(width: 2.0),
                          boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_rounded, size: 22, color: NeoBrutalism.dark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Pusat Bantuan & CS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main White Container with Curvature
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 2.0),
                    left: BorderSide(color: Colors.black, width: 2.0),
                    right: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CS Contact Card (Clickable)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showSupportTicketSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: NeoBrutalism.surfaceWarm,
                              borderRadius: BorderRadius.circular(18),
                              border: NeoBrutalism.border(width: 2.0),
                              boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: NeoBrutalism.primary,
                                    shape: BoxShape.circle,
                                    border: NeoBrutalism.border(width: 1.8),
                                    boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                                  ),
                                  child: const Icon(
                                    Icons.support_agent_rounded,
                                    size: 26,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Customer Service 24/7',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: NeoBrutalism.mint,
                                              borderRadius: BorderRadius.circular(6),
                                              border: NeoBrutalism.border(width: 1.0),
                                            ),
                                            child: Text(
                                              'ONLINE',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Ketuk untuk mengirim keluhan atau chat dengan tim CS',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: NeoBrutalism.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // FAQ Section Title
                        Text(
                          'PERTANYAAN SERING DIAJUKAN (FAQ)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: NeoBrutalism.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // FAQ Accordion List
                        ...List.generate(_faqs.length, (index) {
                          final item = _faqs[index];
                          final isExpanded = _expandedIndex == index;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isExpanded ? NeoBrutalism.primaryLight : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: NeoBrutalism.border(width: 2.0),
                              boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  _expandedIndex = isExpanded ? null : index;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['question']!,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons.keyboard_arrow_down_rounded,
                                          size: 20,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                    if (isExpanded) ...[
                                      const SizedBox(height: 10),
                                      const Divider(color: Colors.black26, height: 1),
                                      const SizedBox(height: 10),
                                      Text(
                                        item['answer']!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          height: 1.5,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
