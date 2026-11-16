import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/service_item.dart';

import 'notion_doodle_icons.dart';
import 'upcoming_feature_bottom_sheet.dart';

class AllServicesBottomSheet extends StatefulWidget {
  const AllServicesBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AllServicesBottomSheet(),
    );
  }

  @override
  State<AllServicesBottomSheet> createState() => _AllServicesBottomSheetState();
}

class _AllServicesBottomSheetState extends State<AllServicesBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _catalogCategories = [
    {
      'title': 'Konsultasi Keuangan (E-Counseling)',
      'tag': 'KONSULTASI',
      'description': 'Sesi privat bersama Certified Financial Planner independen',
      'tagColor': const Color(0xFFD1FAE5),
      'items': [
        const ServiceItem(
          id: 'individu',
          title: 'Individu',
          category: 'counseling',
          svgKey: 'individu',
          badgeColor: Color(0xFFD1FAE5),
          route: '/consult?category=Individu',
          description: 'Konsultasi budgeting & karier pribadi',
        ),
        const ServiceItem(
          id: 'pasangan',
          title: 'Pasangan',
          category: 'counseling',
          svgKey: 'pasangan',
          badgeColor: Color(0xFFFFE4E6),
          route: '/consult?category=Pasangan',
          description: 'Perencanaan keuangan pranikah & pasutri',
        ),
        const ServiceItem(
          id: 'keluarga',
          title: 'Keluarga',
          category: 'counseling',
          svgKey: 'keluarga',
          badgeColor: Color(0xFFE0F2FE),
          route: '/consult?category=Keluarga',
          description: 'Dana pendidikan anak & proteksi keluarga',
        ),
        const ServiceItem(
          id: 'umkm',
          title: 'UMKM & Bisnis',
          category: 'counseling',
          svgKey: 'umkm',
          badgeColor: Color(0xFFFFEDD5),
          route: '/consult?category=Business',
          description: 'Pemisahan uang pribadi & pembukuan usaha',
        ),
        const ServiceItem(
          id: 'corporate',
          title: 'Corporate',
          category: 'counseling',
          svgKey: 'corporate',
          badgeColor: Color(0xFFEDE9FE),
          route: '/consult?category=Business',
          description: 'Program employee financial wellness B2B',
        ),
        const ServiceItem(
          id: 'free_counseling',
          title: 'Konseling Bebas',
          category: 'counseling',
          svgKey: 'free_counseling',
          badgeColor: Color(0xFFFEF08A),
          route: '/match-expert',
          isBadgeFree: true,
          description: 'Sesi perkenalan pencocokan CFP terpercaya',
        ),
        const ServiceItem(
          id: 'audit_portofolio',
          title: 'Audit Polis',
          category: 'counseling',
          svgKey: 'audit_portofolio',
          badgeColor: Color(0xFFCCFBF1),
          route: '/consult?category=Insurance',
          description: 'Review polis asuransi & portofolio proteksi',
        ),
      ],
    },
    {
      'title': 'AI & Smart Money Tracker',
      'tag': 'SMART TRACKER',
      'description': 'Pencatatan mutasi otomatis & asisten AI',
      'tagColor': NeoBrutalism.lime,
      'items': [
        const ServiceItem(
          id: 'ai_clarafin',
          title: 'AI Clarafin',
          category: 'tracker',
          svgKey: 'ai_clarafin',
          badgeColor: NeoBrutalism.lime,
          route: '/ai-chat',
          isBadgeNew: true,
          description: 'Tanya jawab solusi keuangan bersama AI',
        ),
        const ServiceItem(
          id: 'riwayat',
          title: 'Riwayat',
          category: 'tracker',
          svgKey: 'riwayat',
          badgeColor: Color(0xFFF3F4F6),
          route: '/transaction/history',
          description: 'Laporan dan riwayat transaksi lengkap',
        ),
        const ServiceItem(
          id: 'goals',
          title: 'Target Tabungan',
          category: 'tracker',
          svgKey: 'goals',
          badgeColor: Color(0xFFFEF3C7),
          route: '/budget?tab=0',
          description: 'Simulasi dan pemantauan impian finansial',
        ),
        const ServiceItem(
          id: 'bills',
          title: 'Tagihan & Bills',
          category: 'tracker',
          svgKey: 'bills',
          badgeColor: Color(0xFFFFE4E6),
          route: '/budget?tab=2',
          description: 'Pengingat tagihan rutin & langganan',
        ),
        const ServiceItem(
          id: 'emergency_fund',
          title: 'Dana Darurat',
          category: 'tracker',
          svgKey: 'goals',
          badgeColor: Color(0xFFCCFBF1),
          route: '/budget?tab=0',
          description: 'Simulasi alokasi 3-6 bulan pengeluaran rutin',
        ),
      ],
    },
    {
      'title': 'Cek Kesehatan Finansial & Tools',
      'tag': 'CHECK-UP & TOOLS',
      'description': 'Kuis diagnostik & kalkulator mandiri',
      'tagColor': const Color(0xFFEDE9FE),
      'items': [
        const ServiceItem(
          id: 'tes_finansial',
          title: 'Tes Finansial',
          category: 'health_check',
          svgKey: 'tes_finansial',
          badgeColor: Color(0xFFDCFCE7),
          isBadgeNew: true,
          route: '/financial-test',
          description: 'Check-up 3 menit rasio utang & dana darurat',
        ),
        const ServiceItem(
          id: 'tes_kepribadian',
          title: 'Tipe Finansial',
          category: 'health_check',
          svgKey: 'tes_kepribadian',
          badgeColor: Color(0xFFFEF3C7),
          route: '/match-expert',
          description: 'Cari tahu kepribadian uang: hemat vs impulsif',
        ),
        const ServiceItem(
          id: 'score',
          title: 'ClaraScore',
          category: 'health_check',
          svgKey: 'score',
          badgeColor: Color(0xFFEDE9FE),
          route: '/score',
          description: 'Skor kesehatan finansial neobrutalis',
        ),
        const ServiceItem(
          id: 'simulasi_kpr',
          title: 'Simulasi KPR',
          category: 'health_check',
          svgKey: 'kalkulator',
          badgeColor: Color(0xFFE0F2FE),
          route: '/tools/kpr',
          description: 'Simulasi cicilan KPR & rasio DSR penghasilan',
        ),
        const ServiceItem(
          id: 'kalkulator',
          title: 'Kalkulator',
          category: 'health_check',
          svgKey: 'kalkulator',
          badgeColor: Color(0xFFEDE9FE),
          route: '/tools/calculator',
          description: 'Simulasi anuitas pinjaman & cicilan bulanan',
        ),
        const ServiceItem(
          id: 'bebas_hutang',
          title: 'Bebas Hutang',
          category: 'health_check',
          svgKey: 'bebas_hutang',
          badgeColor: Color(0xFFFFE4E6),
          route: '/tools/debt-payoff',
          description: 'Strategi pelunasan utang Snowball vs Avalanche',
        ),
      ],
    },
    {
      'title': 'Kelas & Edukasi Finansial',
      'tag': 'EDUKASI',
      'description': 'Modul & webinar eksklusif perencana keuangan',
      'tagColor': const Color(0xFFFFEDD5),
      'items': [
        const ServiceItem(
          id: 'kelas_online',
          title: 'Kelas Online',
          category: 'education',
          svgKey: 'kelas_online',
          badgeColor: Color(0xFFFEF08A),
          isBadgeSoon: true,
          description: 'Video modul belajar kelola uang dari nol',
        ),
        const ServiceItem(
          id: 'webinar_cfp',
          title: 'Webinar CFP',
          category: 'education',
          svgKey: 'webinar_cfp',
          badgeColor: Color(0xFFCCFBF1),
          isBadgeSoon: true,
          description: 'Sesi webinar live interaktif bersama perencana',
        ),
        const ServiceItem(
          id: 'ebook',
          title: 'E-Book Panduan',
          category: 'education',
          svgKey: 'ebook',
          badgeColor: Color(0xFFEDE9FE),
          isBadgeSoon: true,
          description: 'Kumpulan e-book panduan investasi & pajak',
        ),
      ],
    },
    {
      'title': 'Promo & Rewards',
      'tag': 'HADIAH & PROMO',
      'description': 'Voucher diskon konseling & kado untuk teman',
      'tagColor': const Color(0xFFFEF3C7),
      'items': [
        const ServiceItem(
          id: 'kupon',
          title: 'Kupon Promo',
          category: 'rewards',
          svgKey: 'kupon',
          badgeColor: Color(0xFFFEF3C7),
          route: '/vouchers',
          description: 'Klaim diskon s.d. 50% untuk sesi konseling',
        ),
        const ServiceItem(
          id: 'gift_card',
          title: 'Gift Card',
          category: 'rewards',
          svgKey: 'gift_card',
          badgeColor: Color(0xFFFFE4E6),
          isBadgeSoon: true,
          description: 'Kado sesi konsultasi untuk teman/keluarga',
        ),
        const ServiceItem(
          id: 'referral',
          title: 'Ajak Teman',
          category: 'rewards',
          svgKey: 'referral',
          badgeColor: Color(0xFFDCFCE7),
          isBadgeSoon: true,
          description: 'Dapatkan saldo konsultasi gratis bersama teman',
        ),
      ],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleServiceTap(BuildContext context, ServiceItem item) {
    if (item.onTap != null) {
      Navigator.of(context).pop();
      item.onTap!();
      return;
    }



    if (item.isBadgeSoon) {
      Navigator.of(context).pop();
      UpcomingFeatureBottomSheet.show(context, item);
      return;
    }

    if (item.route != null) {
      Navigator.of(context).pop();
      if (item.route!.startsWith('/consult') ||
          item.route!.startsWith('/home') ||
          item.route!.startsWith('/wallet') ||
          item.route!.startsWith('/budget')) {
        context.go(item.route!);
      } else {
        context.push(item.route!);
      }
      return;
    }

    _showFeatureDetailDialog(context, item);
  }

  void _showFeatureDetailDialog(BuildContext context, ServiceItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
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
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: NeoBrutalism.dark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description ?? 'Fitur e-counseling finansial Clarafin.',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NeoBrutalism.surfaceWarm,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 18, color: NeoBrutalism.dark),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sesi & modul interaktif dapat kamu akses langsung bersama perencana terverifikasi.',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: NeoBrutalism.dark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Tutup',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/consult');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoBrutalism.lime,
              foregroundColor: Colors.black,
              elevation: 0,
              side: const BorderSide(color: Colors.black, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Mulai Sekarang',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
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
          child: Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),

              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Semua Layanan',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Katalog lengkap e-counseling & smart money tools',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: NeoBrutalism.textMuted,
                          ),
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
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: NeoBrutalism.shadow(yOffset: 2),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: NeoBrutalism.dark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari layanan (misal: Pasangan, Pajak, KPR)...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black87),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.clear, size: 18, color: Colors.black54),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Categories List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 40 + MediaQuery.of(context).padding.bottom),
                  itemCount: _catalogCategories.length,
                  itemBuilder: (context, catIndex) {
                    final cat = _catalogCategories[catIndex];
                    final allItems = cat['items'] as List<ServiceItem>;

                    // Filter items by search query
                    final items = query.isEmpty
                        ? allItems
                        : allItems.where((it) {
                            return it.title.toLowerCase().contains(query) ||
                                (it.description?.toLowerCase().contains(query) ?? false);
                          }).toList();

                    if (items.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header with Pill Tag
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: cat['tagColor'] as Color,
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(color: Colors.black, width: 1.5),
                                ),
                                child: Text(
                                  cat['tag'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat['title'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: NeoBrutalism.dark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat['description'] as String,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              color: NeoBrutalism.textMuted,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 4-Column Grid of Service Items
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 14,
                              mainAxisExtent: 90,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, idx) {
                              final it = items[idx];
                              return GestureDetector(
                                onTap: () => _handleServiceTap(context, it),
                                child: Column(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Circle Icon Container
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: it.badgeColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.black, width: 2),
                                            boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
                                          ),
                                          child: Center(
                                            child: NotionDoodleWidget(
                                              svgString: NotionDoodleIcons.getSvg(it.svgKey),
                                              size: 30,
                                            ),
                                          ),
                                        ),

                                        // Free / New / Soon Badge
                                        if (it.isBadgeFree)
                                          Positioned(
                                            top: -3,
                                            right: -3,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981),
                                                borderRadius: BorderRadius.circular(9999),
                                                border: Border.all(color: Colors.black, width: 1.5),
                                              ),
                                              child: const Text(
                                                'FREE',
                                                style: TextStyle(
                                                  fontFamily: 'Plus Jakarta Sans',
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          )
                                        else if (it.isBadgeNew)
                                          Positioned(
                                            top: -3,
                                            right: -3,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: NeoBrutalism.coral,
                                                borderRadius: BorderRadius.circular(9999),
                                                border: Border.all(color: Colors.black, width: 1.5),
                                              ),
                                              child: const Text(
                                                'NEW',
                                                style: TextStyle(
                                                  fontFamily: 'Plus Jakarta Sans',
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          )
                                        else if (it.isBadgeSoon)
                                          Positioned(
                                            top: -3,
                                            right: -3,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: NeoBrutalism.lavender,
                                                borderRadius: BorderRadius.circular(9999),
                                                border: Border.all(color: Colors.black, width: 1.5),
                                              ),
                                              child: const Text(
                                                'SOON',
                                                style: TextStyle(
                                                  fontFamily: 'Plus Jakarta Sans',
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      it.title,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: NeoBrutalism.dark,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
