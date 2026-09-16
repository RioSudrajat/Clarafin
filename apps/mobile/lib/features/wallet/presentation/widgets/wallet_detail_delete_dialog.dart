import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/wallet_model.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';

class WalletDetailDeleteDialog extends StatelessWidget {
  final WalletModel wallet;
  final VoidCallback onConfirmDelete;

  const WalletDetailDeleteDialog({
    super.key,
    required this.wallet,
    required this.onConfirmDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required WalletModel wallet,
    required VoidCallback onConfirmDelete,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => WalletDetailDeleteDialog(
        wallet: wallet,
        onConfirmDelete: onConfirmDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
          border: Border.all(
            color: NeoBrutalism.borderBlack,
            width: 2.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: NeoBrutalism.borderBlack,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: NeoBrutalism.borderBlack,
                  width: 2.0,
                ),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC2626),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hapus Dompet?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: NeoBrutalism.dark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yakin ingin menghapus ${wallet.name}? Aksi ini tidak dapat dibatalkan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: NeoBrutalism.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: NeoBrutalism.dark,
                        side: const BorderSide(color: NeoBrutalism.borderBlack, width: 2.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                        ),
                      ),
                      child: Text(
                        'BATAL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirmDelete();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(NeoBrutalism.radiusSm),
                          side: const BorderSide(color: NeoBrutalism.borderBlack, width: 2.0),
                        ),
                      ),
                      child: Text(
                        'HAPUS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
