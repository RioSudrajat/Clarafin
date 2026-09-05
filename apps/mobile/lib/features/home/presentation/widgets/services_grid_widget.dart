import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/service_item.dart';
import 'all_services_bottom_sheet.dart';
import 'notion_doodle_icons.dart';

class ServicesGridWidget extends StatelessWidget {
  const ServicesGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 8 Primary items for Home Screen (2 rows x 4 columns)
    final row1Items = [
      ServiceItem(
        id: 'individu',
        title: 'Individu',
        category: 'counseling',
        svgKey: 'individu',
        badgeColor: const Color(0xFFD1FAE5), // Mint
        onTap: () => context.push('/consult'),
      ),
      ServiceItem(
        id: 'pasangan',
        title: 'Pasangan',
        category: 'counseling',
        svgKey: 'pasangan',
        badgeColor: const Color(0xFFFFE4E6), // Peach
        onTap: () => context.push('/consult'),
      ),
      ServiceItem(
        id: 'keluarga',
        title: 'Keluarga',
        category: 'counseling',
        svgKey: 'keluarga',
        badgeColor: const Color(0xFFE0F2FE), // Sky
        onTap: () => context.push('/consult'),
      ),
      ServiceItem(
        id: 'ai_clarafin',
        title: 'AI Clarafin',
        category: 'tracker',
        svgKey: 'ai_clarafin',
        badgeColor: NeoBrutalism.lime,
        isBadgeNew: true,
        onTap: () => context.push('/session'),
      ),
    ];

    final row2Items = [
      ServiceItem(
        id: 'umkm',
        title: 'UMKM',
        category: 'counseling',
        svgKey: 'umkm',
        badgeColor: const Color(0xFFFFEDD5), // Soft orange
        onTap: () => context.push('/consult'),
      ),
      ServiceItem(
        id: 'score',
        title: 'Score',
        category: 'health_check',
        svgKey: 'score',
        badgeColor: const Color(0xFFEDE9FE), // Lavender
        onTap: () => context.go('/budget'),
      ),
      ServiceItem(
        id: 'kupon',
        title: 'Kupon',
        category: 'rewards',
        svgKey: 'kupon',
        badgeColor: const Color(0xFFFEF3C7), // Soft yellow
        onTap: () => _showCouponModal(context),
      ),
      ServiceItem(
        id: 'more',
        title: 'Lihat Semua',
        category: 'general',
        svgKey: 'lihat_semua',
        badgeColor: Colors.white,
        onTap: () => AllServicesBottomSheet.show(context),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Layanan
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Layanan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: NeoBrutalism.dark,
                ),
              ),
              GestureDetector(
                onTap: () => AllServicesBottomSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Semua',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: NeoBrutalism.dark,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 14, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Grid 2 Baris x 4 Kolom
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              // Row 1 (Individu, Pasangan, Keluarga, AI Clarafin)
              Row(
                children: row1Items.map((item) {
                  return Expanded(
                    child: _buildServiceItem(context, item),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Row 2 (UMKM, Score, Kupon, Lihat Semua)
              Row(
                children: row2Items.map((item) {
                  return Expanded(
                    child: _buildServiceItem(context, item),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(BuildContext context, ServiceItem item) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Circular Notion Doodle Container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
                ),
                child: Center(
                  child: NotionDoodleWidget(
                    svgString: NotionDoodleIcons.getSvg(item.svgKey),
                    size: 32,
                  ),
                ),
              ),

              // "NEW" Badge on AI Clarafin
              if (item.isBadgeNew)
                Positioned(
                  top: -2,
                  right: -2,
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
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
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
  }

  void _showCouponModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            Row(
              children: const [
                Icon(Icons.local_offer_outlined, size: 24, color: NeoBrutalism.dark),
                SizedBox(width: 8),
                Text(
                  'Kupon & Promo Clarafin',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: NeoBrutalism.dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan kode promo ini saat memesan sesi konseling finansialmu.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: NeoBrutalism.shadow(yOffset: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'CLARAFIN50',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Diskon 50% untuk sesi konsultasi pertamamu',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.push('/consult');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NeoBrutalism.lime,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Pakai', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: NeoBrutalism.shadow(yOffset: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'FREE15MIN',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Gratis sesi perkenalan & discovery 15 menit',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.push('/consult');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Klaim', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
