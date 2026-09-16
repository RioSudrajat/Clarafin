import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class TransactionSuccessActionButtons extends StatelessWidget {
  final String? returnTo;

  const TransactionSuccessActionButtons({
    super.key,
    this.returnTo,
  });

  @override
  Widget build(BuildContext context) {
    final hasReturnTo = returnTo != null && returnTo!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          if (hasReturnTo) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.go(returnTo!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NeoBrutalism.dark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                    side: const BorderSide(color: NeoBrutalism.borderBlack, width: 2.0),
                  ),
                ),
                child: Text(
                  'KEMBALI KE GOAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NeoBrutalism.lime,
                foregroundColor: NeoBrutalism.dark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                  side: const BorderSide(color: NeoBrutalism.borderBlack, width: 2.0),
                ),
              ),
              child: Text(
                hasReturnTo ? 'KE BERANDA' : 'SELESAI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => context.push('/transaction/history'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: NeoBrutalism.dark,
                side: const BorderSide(color: NeoBrutalism.borderBlack, width: 2.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                ),
              ),
              child: Text(
                'LIHAT RIWAYAT TRANSAKSI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
