import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class FinancialTestCatalogScreen extends StatefulWidget {
  const FinancialTestCatalogScreen({super.key});

  @override
  State<FinancialTestCatalogScreen> createState() => _FinancialTestCatalogScreenState();
}

class _FinancialTestCatalogScreenState extends State<FinancialTestCatalogScreen> {
  int _selectedTierIndex = 0;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<Map<String, dynamic>> _checkupTiers = [
    {
      'tag': 'Financial Check-Up • Basic',
      'title': 'Bongkar Bocor Halus & Skor Keuanganmu',
      'duration': '45 Menit',
      'consultantType': 'AWP® / QWP® (< 300 klien)',
      'onlinePrice': 149000.0,
      'offlinePrice': 279000.0,
      'badgeColor': NeoBrutalism.mint,
      'desc': 'Sesi bedah cepat untuk mendeteksi pos kebocoran dana dan mendapatkan rapor skor 4 rasio keuangan utama beserta resep aksi 30 hari.',
      'deliverables': [
        'Rapor skor 4 rasio: Tabungan, Utang, Dana Darurat, & Gaya Hidup',
        'Deteksi pos pengeluaran impulsif & langganan tak terpakai',
        'Resep perbaikan cashflow 30 hari dalam format ringkas',
        'Sesi tanya jawab privat 45 menit (Call/Video/Chat)',
      ],
      'recommendedConsultantId': 'c3', // Rian Pratama, QWP®, AWP®
    },
    {
      'tag': 'Financial Check-Up • Medium',
      'title': 'Bedah Tuntas Portofolio & Polis Asuransi',
      'duration': '60 Menit',
      'consultantType': 'Senior CFP® (301–500 klien)',
      'onlinePrice': 279000.0,
      'offlinePrice': 429000.0,
      'badgeColor': NeoBrutalism.lime,
      'desc': 'Audit menyeluruh polis asuransi yang sudah dibeli agar premi tidak kemahalan dan racikan investasi sudah optimal sesuai tujuan.',
      'deliverables': [
        'Audit independen polis asuransi jiwa, kesehatan, & penyakit kritis',
        'Evaluasi alokasi reksa dana, obligasi SBN, saham, & emas',
        'Rekomendasi rebalancing aset tanpa bias komisi penjualan agen',
        'Sesi konsultasi 60 menit + rangkuman rekomendasi tertulis',
      ],
      'recommendedConsultantId': 'c1', // Chrysan Gomargana, CFP®
    },
    {
      'tag': 'Financial Check-Up • Premium',
      'title': 'Peta Jalan Kekayaan & Pensiun Dini (360°)',
      'duration': '90 Menit',
      'consultantType': 'Principal CFP® / CFA® (> 500 klien)',
      'onlinePrice': 499000.0,
      'offlinePrice': 699000.0,
      'badgeColor': NeoBrutalism.lavender,
      'desc': 'Pemeriksaan kesehatan finansial holistik menghasilkan Master Financial Blueprint PDF 10 tahun untuk meraih Financial Freedom (FIRE).',
      'deliverables': [
        'Dokumen Master Financial Blueprint PDF proyeksi 10 tahun',
        'Kalkulasi angka pasti dana pensiun dini (FIRE) & inflasi riil',
        'Matriks alokasi aset multi-instrumen & efisiensi pajak SPT',
        'Sesi intensif 90 menit bersama Principal CFP®/CFA®',
      ],
      'recommendedConsultantId': 'c4', // Dr. Hendra Wijaya, CFA®, CFP®
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeTier = _checkupTiers[_selectedTierIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F758A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: NeoBrutalism.brandGradient,
        ),
        child: Column(
          children: [
            // Pinned Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
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
                      'Tes Finansial (Check-Up)',
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

            // White Canvas
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
                        // Hero Hook Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: NeoBrutalism.surfaceWarm,
                            borderRadius: BorderRadius.circular(16),
                            border: NeoBrutalism.border(width: 2.0),
                            boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: NeoBrutalism.lime,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 1.5),
                                ),
                                child: const Icon(Icons.health_and_safety_rounded, color: Colors.black, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Medical Check-Up Keuangan',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: NeoBrutalism.dark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Cari tahu bocor halus di dompetmu sebelum menjadi masalah besar bersama perencana keuangan berlisensi.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: NeoBrutalism.textMuted,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tier Selection Tabs
                        Text(
                          'Pilih Paket Financial Check-Up',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: List.generate(_checkupTiers.length, (index) {
                            final tier = _checkupTiers[index];
                            final isSelected = _selectedTierIndex == index;
                            final shortTierName = (tier['tag'] as String).split('•').last.trim();

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTierIndex = index),
                                child: Container(
                                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? NeoBrutalism.lime : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: NeoBrutalism.border(width: 2.0),
                                    boxShadow: isSelected
                                        ? NeoBrutalism.shadow(yOffset: 3.0)
                                        : NeoBrutalism.shadow(yOffset: 1.5),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        shortTierName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currencyFormat.format(tier['onlinePrice']),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F758A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),

                        // Active Tier Card Detail
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: NeoBrutalism.border(width: 2.0),
                            boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: activeTier['badgeColor'] as Color,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.black, width: 1.2),
                                ),
                                child: Text(
                                  activeTier['tag'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                activeTier['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF0F758A)),
                                  const SizedBox(width: 4),
                                  Text(
                                    activeTier['duration'] as String,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0F758A)),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.workspace_premium_outlined, size: 14, color: Colors.black54),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      activeTier['consultantType'] as String,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                activeTier['desc'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF374151),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1, color: Colors.black12),
                              const SizedBox(height: 12),
                              Text(
                                'Output yang Kamu Dapatkan:',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(activeTier['deliverables'] as List<String>).map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF0F758A)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1F2937),
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Booking CTA Button
                        GestureDetector(
                          onTap: () {
                            final consultantId = activeTier['recommendedConsultantId'] as String;
                            context.push('/booking/$consultantId/service');
                          },
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: NeoBrutalism.lime,
                              borderRadius: BorderRadius.circular(14),
                              border: NeoBrutalism.border(width: 2.0),
                              boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 20, color: Colors.black),
                                const SizedBox(width: 8),
                                Text(
                                  'Pesan Sesi Check-Up (${currencyFormat.format(activeTier['onlinePrice'])})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Alternative: See ClaraScore
                        Center(
                          child: TextButton.icon(
                            onPressed: () => context.push('/score'),
                            icon: const Icon(Icons.speed_rounded, size: 16, color: Color(0xFF0F758A)),
                            label: Text(
                              'Lihat Skor Otomatis Saya (ClaraScore)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F758A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
