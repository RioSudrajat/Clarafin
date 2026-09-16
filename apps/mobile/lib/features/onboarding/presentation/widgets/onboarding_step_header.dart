import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class OnboardingStepHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  const OnboardingStepHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (onBack != null)
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                    border: NeoBrutalism.border(width: 2.0),
                    boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back, size: 20, color: NeoBrutalism.dark),
                  ),
                ),
              )
            else
              const SizedBox(width: 42),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: NeoBrutalism.lime,
                borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                border: NeoBrutalism.border(width: 2.0),
                boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
              ),
              child: Text(
                'LANGKAH $step DARI $totalSteps',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: NeoBrutalism.dark,
                ),
              ),
            ),
            if (onSkip != null)
              GestureDetector(
                onTap: onSkip,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    'Lewati',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 42),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: NeoBrutalism.dark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
