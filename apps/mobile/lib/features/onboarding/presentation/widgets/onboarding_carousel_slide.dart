import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class OnboardingCarouselSlide extends StatelessWidget {
  final String tag;
  final String title;
  final String desc;
  final IconData icon;
  final Color bg;

  const OnboardingCarouselSlide({
    super.key,
    required this.tag,
    required this.title,
    required this.desc,
    required this.icon,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(NeoBrutalism.radiusXl),
            border: NeoBrutalism.border(width: 2.0),
            boxShadow: NeoBrutalism.shadow(yOffset: 4.0),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                    border: NeoBrutalism.border(width: 1.5),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: NeoBrutalism.border(width: 2.0),
                  boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
                ),
                child: Center(
                  child: Icon(icon, size: 40, color: NeoBrutalism.dark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: NeoBrutalism.dark,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
