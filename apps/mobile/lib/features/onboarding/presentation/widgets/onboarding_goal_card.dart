import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class OnboardingGoalCard extends StatelessWidget {
  final String title;
  final String description;
  final String targetNominal;
  final String? badge;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const OnboardingGoalCard({
    super.key,
    required this.title,
    required this.description,
    required this.targetNominal,
    this.badge,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF7FEE7) : Colors.white,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.black,
            width: isSelected ? 2.5 : 2.0,
          ),
          boxShadow: NeoBrutalism.shadow(
            yOffset: isSelected ? 1.5 : 3.0,
            color: Colors.black,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected ? NeoBrutalism.lime : AppColors.background,
                    borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                    border: NeoBrutalism.border(width: 2.0),
                  ),
                  child: Center(
                    child: Icon(icon, size: 22, color: NeoBrutalism.dark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: NeoBrutalism.dark,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: NeoBrutalism.lime,
                                borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
                                border: NeoBrutalism.border(width: 1.5),
                              ),
                              child: Text(
                                badge!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: NeoBrutalism.dark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSelected ? NeoBrutalism.dark : Colors.white,
                    shape: BoxShape.circle,
                    border: NeoBrutalism.border(width: 2.0),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: NeoBrutalism.lime)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : AppColors.background,
                borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                border: NeoBrutalism.border(width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Target Mulai: ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    targetNominal,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
