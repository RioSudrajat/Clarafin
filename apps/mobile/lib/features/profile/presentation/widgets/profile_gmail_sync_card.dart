import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/user_profile_provider.dart';

class ProfileGmailSyncCard extends ConsumerWidget {
  const ProfileGmailSyncCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final isConnected = profile.isGmailConnected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(NeoBrutalism.radiusLg),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isConnected ? const Color(0xFFDC2626) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: NeoBrutalism.border(width: 1.5),
            ),
            child: Icon(
              Icons.mail_rounded,
              size: 20,
              color: isConnected ? Colors.white : NeoBrutalism.dark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SINKRONISASI RESI GMAIL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: NeoBrutalism.teal,
                      ),
                    ),
                    Switch(
                      value: isConnected,
                      onChanged: (val) {
                        ref.read(userProfileProvider.notifier).toggleGmailConnection(val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val
                                  ? 'Gmail terhubung! Transaksi struk & mutasi akan otomatis dipindai.'
                                  : 'Koneksi Gmail dinonaktifkan.',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                            ),
                            backgroundColor: val ? NeoBrutalism.teal : NeoBrutalism.dark,
                          ),
                        );
                      },
                      activeThumbColor: NeoBrutalism.lime,
                      activeTrackColor: NeoBrutalism.dark,
                    ),
                  ],
                ),
                Text(
                  'Deteksi otomatis struk digital & mutasi bank dari email Anda.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: NeoBrutalism.dark,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isConnected ? NeoBrutalism.mint : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: NeoBrutalism.border(width: 1.0),
                  ),
                  child: Text(
                    isConnected ? '● Auto-Sync Aktif (30 Hari Terakhir)' : '○ Belum Terhubung',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isConnected ? const Color(0xFF15803D) : NeoBrutalism.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
