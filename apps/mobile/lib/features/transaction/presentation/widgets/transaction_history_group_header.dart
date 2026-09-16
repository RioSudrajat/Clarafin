import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class TransactionHistoryGroupHeader extends StatelessWidget {
  final String dateTitle;

  const TransactionHistoryGroupHeader({
    super.key,
    required this.dateTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        dateTitle.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: NeoBrutalism.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
