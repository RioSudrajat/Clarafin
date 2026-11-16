import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DeleteAccountDialog {
  static void show(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
          side: const BorderSide(color: Colors.black, width: 2.0),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFBA1A1A),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hapus Akun Permanen?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tindakan ini tidak dapat dibatalkan. Seluruh data dompet, transaksi, target, analisis AI, dan riwayat konsultasimu akan dihapus secara permanen dari perangkat ini.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sesi akan langsung ditutup dan diarahkan ke pendaftaran baru.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.of(ctx).pop();
              try {
                final currentUserId = ref.read(authProvider).currentUser?.id;
                if (currentUserId != null) {
                  ref.read(localStorageServiceProvider).clearAll();
                }
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.black, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Akun dan seluruh data lokal berhasil dihapus.',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: NeoBrutalism.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.go('/register');
                }
              } catch (_) {
                if (context.mounted) {
                  context.go('/register');
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFBA1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 0),
                ],
              ),
              child: Text(
                'Ya, Hapus Akun',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
