import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class TransactionHistoryEmptyState extends StatelessWidget {
  const TransactionHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: NeoBrutalism.borderBlack,
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: NeoBrutalism.borderBlack,
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: NeoBrutalism.dark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Transaksi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: NeoBrutalism.dark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada transaksi yang cocok dengan kriteria filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NeoBrutalism.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
