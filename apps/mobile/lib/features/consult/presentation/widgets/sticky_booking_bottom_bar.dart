import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class StickyBookingBottomBar extends StatelessWidget {
  final double price;
  final String buttonText;
  final VoidCallback? onTap;

  const StickyBookingBottomBar({
    super.key,
    required this.price,
    this.buttonText = 'Selanjutnya',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isEnabled = onTap != null;

    return CustomPaint(
      foregroundPainter: const _RoundedTopBorderPainter(
        radius: 24.0,
        strokeWidth: 2.0,
        color: Colors.black,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Harga',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: NeoBrutalism.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  price <= 0 ? '-' : currencyFormat.format(price),
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const Spacer(),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                constraints: const BoxConstraints(minWidth: 130, maxWidth: 170),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: isEnabled ? NeoBrutalism.lime : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isEnabled ? Colors.black : const Color(0xFFE5E7EB),
                    width: isEnabled ? 2.0 : 1.5,
                  ),
                  boxShadow: isEnabled
                      ? const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(0, 2.5),
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    buttonText,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: isEnabled ? NeoBrutalism.dark : const Color(0xFF9CA3AF),
                    ),
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
}

class _RoundedTopBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final Color color;

  const _RoundedTopBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final halfStroke = strokeWidth / 2;
    final r = radius.clamp(0.0, size.width / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(halfStroke, r)
      ..arcToPoint(
        Offset(r, halfStroke),
        radius: Radius.circular(r),
      )
      ..lineTo(size.width - r, halfStroke)
      ..arcToPoint(
        Offset(size.width - halfStroke, r),
        radius: Radius.circular(r),
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoundedTopBorderPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.color != color;
}
