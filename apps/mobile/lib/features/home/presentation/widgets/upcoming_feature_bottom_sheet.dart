import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/service_item.dart';
import 'notion_doodle_icons.dart';

class UpcomingFeatureBottomSheet extends StatelessWidget {
  final ServiceItem item;

  const UpcomingFeatureBottomSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, ServiceItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UpcomingFeatureBottomSheet(item: item),
    );
  }

  Map<String, dynamic> _getFeatureDetails() {
    switch (item.id) {
      case 'kelas_online':
        return {
          'tag': 'VIDEO KURIKULUM • Q2 2026',
          'description':
              'Modul video komprehensif dari merapikan arus kas harian, mengikis utang konsumtif, hingga membangun portofolio investasi saham & reksadana secara mandiri.',
          'highlights': [
            '12 Modul Video HD bersama Certified Financial Planner',
            'Template Budgeting Spreadsheet & Kalkulator Pensiun',
            'Sertifikat Kelulusan & Akses Komunitas Eksklusif',
          ],
        };
      case 'webinar_cfp':
        return {
          'tag': 'LIVE WEBINAR • BULANAN',
          'description':
              'Sesi interaktif berkala yang mengupas tuntas isu finansial aktual, strategi pajak UMKM, proteksi keluarga, dan bedah portofolio investasi anti-inflasi.',
          'highlights': [
            'Sesi Live Zoom 90 Menit bersama Praktisi CFP',
            'Bedah Kasus Nyata & Studi Portofolio Finansial',
            'Sesi Tanya Jawab Langsung (Q&A Terbuka)',
          ],
        };
      case 'ebook':
        return {
          'tag': 'E-BOOK EKSKLUSIF • Q2 2026',
          'description':
              'Buku digital kurasi praktis tanpa jargon rumit, dirancang oleh perencana keuangan independen untuk memandu keputusan finansial pentingmu.',
          'highlights': [
            '3 Seri E-Book: Pajak UMKM, Audit Polis, & Panduan KPR',
            'Checklist Lengkap Produk Keuangan Berizin OJK',
            'Format PDF & EPUB Nyaman Dibaca di Smartphone',
          ],
        };
      case 'gift_card':
        return {
          'tag': 'KADO FINANSIAL • Q2 2026',
          'description':
              'Hadiah literasi paling bermakna untuk sahabat pranikah, keluarga, atau pasangan baru untuk memulai masa depan finansial yang tenang dan terencana.',
          'highlights': [
            'Voucher Konsultasi 1-on-1 dengan CFP Pilihan',
            'Personalisasi Ucapan & Desain Kartu Digital',
            'Masa Berlaku Fleksibel hingga 12 Bulan',
          ],
        };
      case 'referral':
      default:
        return {
          'tag': 'PROGRAM REFERRAL • Q2 2026',
          'description':
              'Ajak teman terdekatmu untuk mulai merapikan masa depan finansial bersama Clarafin dan dapatkan reward saldo konsultasi untuk kalian berdua.',
          'highlights': [
            'Saldo Sesi Rp 50.000 untuk Kamu dan Temanmu',
            'Kode Referral Unik Tanpa Batas Penggunaan',
            'Terkoneksi Otomatis ke Saldo Dompet Clarafin',
          ],
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = _getFeatureDetails();
    final highlights = details['highlights'] as List<String>;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
          top: BorderSide(color: Colors.black, width: 2.5),
          left: BorderSide(color: Colors.black, width: 2),
          right: BorderSide(color: Colors.black, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: item.badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: NeoBrutalism.shadow(yOffset: 2),
                        ),
                        child: Center(
                          child: NotionDoodleWidget(
                            svgString: NotionDoodleIcons.getSvg(item.svgKey),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: NeoBrutalism.dark,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: NeoBrutalism.lavender,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black, width: 1.2),
                            ),
                            child: Text(
                              details['tag'] as String,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: NeoBrutalism.shadow(yOffset: 2),
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Description
              Text(
                details['description'] as String,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 16),

              // Curriculum Highlights Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NeoBrutalism.surfaceWarm,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 1.8),
                  boxShadow: NeoBrutalism.shadow(yOffset: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRATINJAU MATERI & KEUNTUNGAN',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...highlights.map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: NeoBrutalism.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                h,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: NeoBrutalism.dark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Notifikasi berhasil diaktifkan! Kami akan memberi kabar saat fitur ini rilis.',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            backgroundColor: Colors.black,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: NeoBrutalism.lime, width: 1.5),
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.black, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Ingatkan Saya',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/consult');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NeoBrutalism.lime,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.black, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor: Colors.black,
                      ),
                      child: const Text(
                        'Konsultasi CFP',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
