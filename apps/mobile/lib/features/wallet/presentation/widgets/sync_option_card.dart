import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Neo-brutalist option card for sync choice.
class SyncOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const SyncOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: NeoBrutalism.cardDecoration(
          backgroundColor: backgroundColor,
          borderRadius: 20,
          shadowOffset: 3.0,
          borderWidth: 2.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: NeoBrutalism.circleDecoration(
                backgroundColor: iconBgColor,
                borderWidth: 2.0,
                shadowOffset: 0,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: NeoBrutalism.pillDecoration(
                            backgroundColor: NeoBrutalism.lime,
                            borderWidth: 1.5,
                            shadowOffset: 0,
                          ),
                          child: Text(
                            badgeText!,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              color: NeoBrutalism.dark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      color: NeoBrutalism.textMuted,
                      height: 1.3,
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
