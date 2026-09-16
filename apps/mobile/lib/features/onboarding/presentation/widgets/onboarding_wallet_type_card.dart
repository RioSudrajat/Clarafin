import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class OnboardingWalletTypeCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const OnboardingWalletTypeCard({
    super.key,
    required this.label,
    required this.description,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? NeoBrutalism.lime : Colors.white,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusMd),
          border: NeoBrutalism.border(width: 2.0),
          boxShadow: NeoBrutalism.shadow(
            yOffset: isSelected ? 1.5 : 3.0,
            color: Colors.black,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : AppColors.background,
                borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                border: NeoBrutalism.border(width: 2.0),
              ),
              child: Center(
                child: Icon(icon, size: 22, color: NeoBrutalism.dark),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.dark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? const Color(0xFF1E293B) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }
}
