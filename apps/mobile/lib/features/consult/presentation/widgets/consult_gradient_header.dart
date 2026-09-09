import 'package:flutter/material.dart';

/// Top header widget for the Consultation screen.
/// Features the brand teal-to-lime gradient, centered bold title,
/// top-right circular filter action, and a curved white bottom boundary with a 2px black border.
class ConsultGradientHeader extends StatelessWidget {
  final double topSafeArea;
  final VoidCallback? onFilterTap;

  const ConsultGradientHeader({
    super.key,
    required this.topSafeArea,
    this.onFilterTap,
  });

  static const double _curveRadius = 28.0;

  @override
  Widget build(BuildContext context) {
    final headerHeight = topSafeArea + 10.0 + 40.0 + 16.0 + _curveRadius;

    return SizedBox(
      height: headerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Teal to Lime Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F758A), // Deep teal
                    Color(0xFF198696),
                    Color(0xFF8AD830),
                    Color(0xFFBFFF00), // Bright Lime Green
                  ],
                  stops: [0.0, 0.25, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // 2. White Sheet Top Boundary (Curved Container)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _curveRadius,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(_curveRadius),
                ),
              ),
            ),
          ),

          // 3. 2px Black Border along the Curve
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _curveRadius,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WhiteSheetBorderPainter(whiteSheetTop: 0),
              ),
            ),
          ),

          // 4. Header Content (Centered Title + Right Circular Filter Button)
          Positioned(
            top: topSafeArea + 10,
            left: 20,
            right: 20,
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Balanced spacer so title is centered
                const SizedBox(width: 40),

                // Centered Screen Title
                const Text(
                  'Consultation',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),

                // Circular Filter Button (2px black border, 2px shadow)
                GestureDetector(
                  onTap: onFilterTap,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(0, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.filter_list_rounded,
                        size: 20,
                        color: Colors.black,
                      ),
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

/// Draws a continuous 2px black line along the top curved edge of the white sheet.
class _WhiteSheetBorderPainter extends CustomPainter {
  final double whiteSheetTop;
  static const double cornerRadius = 28.0;

  const _WhiteSheetBorderPainter({
    required this.whiteSheetTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final r = cornerRadius;
    final y = whiteSheetTop;
    final w = size.width;

    final path = Path();
    path.moveTo(0, y + r);
    path.arcToPoint(
      Offset(r, y + 1.0),
      radius: const Radius.circular(cornerRadius),
      clockwise: true,
    );
    path.lineTo(w - r, y + 1.0);
    path.arcToPoint(
      Offset(w, y + r),
      radius: const Radius.circular(cornerRadius),
      clockwise: true,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WhiteSheetBorderPainter oldPainter) {
    return oldPainter.whiteSheetTop != whiteSheetTop;
  }
}
