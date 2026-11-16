import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../shared/widgets/interactive_donut_chart.dart';

/// Top header section for the Wallet screen.
/// Features the brand teal-to-lime gradient background, centered title,
/// interactive donut chart in a Neo-Brutalist card, and a curved white bottom boundary.
class WalletGradientHeader extends StatelessWidget {
  final double topSafeArea;
  final String totalBalanceFormatted;
  final List<ChartData> chartData;
  final VoidCallback? onAddTap;
  final VoidCallback? onSortTap;
  final bool? sortByValueAsc;

  const WalletGradientHeader({
    super.key,
    required this.topSafeArea,
    required this.totalBalanceFormatted,
    required this.chartData,
    this.onAddTap,
    this.onSortTap,
    this.sortByValueAsc,
  });

  static const double _curveRadius = 18.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: NeoBrutalism.brandGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topSafeArea + 10),

          // Header Bar: [+ Tambah] (Kiri)  --  [Wallet Finansialmu] (Tengah)  --  [Sort] (Kanan)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: "+ Tambah" button
                GestureDetector(
                  onTap: onAddTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: NeoBrutalism.lime,
                      borderRadius: BorderRadius.circular(10),
                      border: NeoBrutalism.border(width: 1.8),
                      boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 16, color: Colors.black),
                        const SizedBox(width: 3),
                        Text(
                          'Tambah',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Center: Title
                Text(
                  'Wallet Finansialmu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),

                // Right: "Sort" button
                GestureDetector(
                  onTap: onSortTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: sortByValueAsc != null ? NeoBrutalism.lime : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: NeoBrutalism.border(width: 1.8),
                      boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sortByValueAsc == null
                              ? Icons.swap_vert_rounded
                              : (sortByValueAsc! ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                          size: 15,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          sortByValueAsc == null
                              ? 'Sort'
                              : (sortByValueAsc! ? 'Terendah' : 'Tertinggi'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Donut Chart Neo-Brutalist Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: InteractiveDonutChart(
              centerTitle: 'Total Balance',
              centerAmount: totalBalanceFormatted,
              data: chartData,
            ),
          ),
          const SizedBox(height: 6),

          // Curved White Sheet Boundary at Bottom
          SizedBox(
            height: _curveRadius,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(_curveRadius),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _WhiteSheetCurvePainter(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the 2px black line along the top curved edge of the white sheet.
class _WhiteSheetCurvePainter extends CustomPainter {
  static const double cornerRadius = 18.0;

  const _WhiteSheetCurvePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(0, cornerRadius);
    path.arcToPoint(
      const Offset(cornerRadius, 0),
      radius: const Radius.circular(cornerRadius),
      clockwise: true,
    );
    path.lineTo(size.width - cornerRadius, 0);
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: const Radius.circular(cornerRadius),
      clockwise: true,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WhiteSheetCurvePainter oldDelegate) => false;
}
