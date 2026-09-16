import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class AuthSocialDivider extends StatelessWidget {
  final String label;

  const AuthSocialDivider({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: Color(0xFFE5E7EB),
            thickness: 2.0,
            height: 2.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(NeoBrutalism.radiusPill),
              border: NeoBrutalism.border(width: 1.5, color: const Color(0xFFD1D5DB)),
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: Color(0xFFE5E7EB),
            thickness: 2.0,
            height: 2.0,
          ),
        ),
      ],
    );
  }
}
