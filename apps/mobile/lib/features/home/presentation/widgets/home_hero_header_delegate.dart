import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class HomeHeroHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topSafeArea;
  final Widget topBar;
  final Widget Function(BuildContext context, double progress) cardBuilder;
  final int heroPage;

  HomeHeroHeaderDelegate({
    required this.topSafeArea,
    required this.topBar,
    required this.cardBuilder,
    required this.heroPage,
  });

  @override
  double get maxExtent => topSafeArea + 296.0;

  @override
  double get minExtent => topSafeArea + 144.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final cardHeight = lerpDouble(198.0, 64.0, progress)!;
    final dotsOpacity = (1.0 - progress * 3.5).clamp(0.0, 1.0);
    final cardTop = topSafeArea + 62.0;
    final whiteSheetTop = cardTop + (cardHeight / 2);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Dark Teal Gradient Background (Clipped to region ABOVE white sheet boundary)
        Positioned.fill(
          child: ClipPath(
            clipper: _TealHeaderClipper(whiteSheetTop: whiteSheetTop),
            child: Container(
              decoration: const BoxDecoration(
                gradient: NeoBrutalism.brandGradient,
              ),
            ),
          ),
        ),

        // 2. White Sheet Top Boundary Curve & 2px Black Border
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WhiteSheetBorderPainter(whiteSheetTop: whiteSheetTop),
            ),
          ),
        ),

        // 3. Top App Bar (Clarafin Logo + Bell + Avatar)
        Positioned(
          top: topSafeArea + 8,
          left: 20,
          right: 20,
          height: 44,
          child: topBar,
        ),

        // 4. Hero Card (Shrinks from 198px to 64px)
        Positioned(
          top: cardTop,
          left: 12,
          right: 12,
          height: cardHeight,
          child: cardBuilder(context, progress),
        ),

        // 5. Indicator Dots (Fades out when scrolling)
        if (dotsOpacity > 0.01)
          Positioned(
            top: cardTop + cardHeight + 8,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: dotsOpacity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  2,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: heroPage == i ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      color: heroPage == i ? NeoBrutalism.dark : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant HomeHeroHeaderDelegate oldDelegate) => true;
}

// ── Teal Gradient Clipper: Clips exactly to region ABOVE the curved white sheet ──

class _TealHeaderClipper extends CustomClipper<Path> {
  final double whiteSheetTop;
  static const double cornerRadius = 28.0;

  const _TealHeaderClipper({
    required this.whiteSheetTop,
  });

  @override
  Path getClip(Size size) {
    final fullRect = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height + 2000));
    final whiteSheetRRect = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            0,
            whiteSheetTop,
            size.width,
            size.height + 2000,
          ),
          topLeft: const Radius.circular(cornerRadius),
          topRight: const Radius.circular(cornerRadius),
        ),
      );

    return Path.combine(PathOperation.difference, fullRect, whiteSheetRRect);
  }

  @override
  bool shouldReclip(covariant _TealHeaderClipper oldClipper) {
    return oldClipper.whiteSheetTop != whiteSheetTop;
  }
}

// ── White Sheet Top Border Painter: Draws 2px black line along the curve ──

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
      Offset(r, y),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.lineTo(w - r, y);
    path.arcToPoint(
      Offset(w, y + r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WhiteSheetBorderPainter oldPainter) {
    return oldPainter.whiteSheetTop != whiteSheetTop;
  }
}
