import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

/// Neo-Brutalist submit button for ManualWalletEntryScreen.
class ManualWalletSubmitButton extends StatelessWidget {
  final VoidCallback onTap;

  const ManualWalletSubmitButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: NeoBrutalism.cardDecoration(
          backgroundColor: NeoBrutalism.lime,
          borderRadius: 16,
          shadowOffset: 3.5,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Text(
              'SIMPAN DOMPET',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.5,
                color: NeoBrutalism.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
