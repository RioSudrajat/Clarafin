import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../../shared/widgets/interactive_donut_chart.dart';

/// Top header section for the Wallet screen.
/// Features the brand teal-to-lime gradient background, centered title,
/// interactive donut chart in a Neo-Brutalist card, and a curved white bottom boundary.
class WalletGradientHeader extends StatelessWidget {
  final double topSafeArea;
  final String totalBalanceFormatted;
  final List<ChartData> chartData;

  const WalletGradientHeader({
    super.key,
    required this.topSafeArea,
    required this.totalBalanceFormatted,
    required this.chartData,
  });

  static const double _curveRadius = 28.0;

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

          // Screen Title
          const Center(
            child: Text(
              'Wallet Finansialmu',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
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
          const SizedBox(height: 14),

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
  static const double cornerRadius = 28.0;

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
