import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/neo_brutalism_decorations.dart';

/// Individual Neo-Brutalist subscription tier card used inside [SaasUpgradeBottomSheet].
class SaasPlanTierCard extends StatelessWidget {
  final String title;
  final String price;
  final String quotaSummary;
  final List<String> details;
  final Color backgroundColor;
  final Color ctaColor;
  final bool isActive;
  final String ctaLabel;
  final VoidCallback onTap;

  const SaasPlanTierCard({
    super.key,
    required this.title,
    required this.price,
    required this.quotaSummary,
    required this.details,
    required this.backgroundColor,
    required this.ctaColor,
    required this.isActive,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: NeoBrutalism.cardDecoration(
        backgroundColor: backgroundColor,
        borderRadius: NeoBrutalism.radiusMd,
        shadowOffset: 3.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: NeoBrutalism.dark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? NeoBrutalism.teal : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: NeoBrutalism.border(width: 1.5),
                ),
                child: Text(
                  price,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : NeoBrutalism.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            quotaSummary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: NeoBrutalism.teal,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in details)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_rounded, size: 15, color: NeoBrutalism.dark),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isActive ? Colors.white : ctaColor,
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
              border: NeoBrutalism.border(width: 2.0),
              boxShadow: isActive ? null : NeoBrutalism.shadow(yOffset: 2.0),
            ),
            child: Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
              child: InkWell(
                borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                onTap: isActive ? null : onTap,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  alignment: Alignment.center,
                  child: Text(
                    ctaLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
