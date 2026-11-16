import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/delete_account_dialog.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  void _showChangePinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2.0),
        ),
        title: Text(
          'Ubah 6-Digit PIN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan PIN baru untuk autentikasi transaksi.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2.0),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
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
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (controller.text.length == 6) {
                ref.read(userProfileProvider.notifier).setPin(controller.text);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'PIN berhasil diperbarui!',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    backgroundColor: NeoBrutalism.primary,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: NeoBrutalism.primary,
                borderRadius: BorderRadius.circular(10),
                border: NeoBrutalism.border(width: 1.5),
                boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
              ),
              child: Text(
                'Simpan PIN',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F758A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: NeoBrutalism.brandGradient,
        ),
        child: Column(
          children: [
            // Pinned Neo-Brutalist Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: NeoBrutalism.border(width: 2.0),
                          boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back_rounded, size: 22, color: NeoBrutalism.dark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Keamanan & PIN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main White Container with Curvature
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 2.0),
                    left: BorderSide(color: Colors.black, width: 2.0),
                    right: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Biometric Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: NeoBrutalism.surfaceWarm,
                            borderRadius: BorderRadius.circular(16),
                            border: NeoBrutalism.border(width: 2.0),
                            boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: NeoBrutalism.primary,
                                  shape: BoxShape.circle,
                                  border: NeoBrutalism.border(width: 1.5),
                                ),
                                child: const Icon(Icons.fingerprint_rounded, color: Colors.black, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Biometrik (Fingerprint / Face ID)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Login dan konfirmasi transaksi cepat',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: NeoBrutalism.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: profile.biometricsEnabled,
                                activeThumbColor: Colors.black,
                                activeTrackColor: NeoBrutalism.primary,
                                onChanged: (_) {
                                  ref.read(userProfileProvider.notifier).toggleBiometrics();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // PIN Change Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: NeoBrutalism.border(width: 2.0),
                            boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: NeoBrutalism.mint,
                                  shape: BoxShape.circle,
                                  border: NeoBrutalism.border(width: 1.5),
                                ),
                                child: const Icon(Icons.pin_outlined, color: Colors.black, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ganti 6-Digit PIN Transaksi',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PIN digunakan untuk otorisasi transfer & ekspor',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: NeoBrutalism.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showChangePinDialog(context, ref),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: NeoBrutalism.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    border: NeoBrutalism.border(width: 1.5),
                                    boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                                  ),
                                  child: Text(
                                    'Ubah',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Device Activity Section
                        Text(
                          'PERANGKAT TERHUBUNG',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: NeoBrutalism.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: NeoBrutalism.border(width: 2.0),
                            boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: NeoBrutalism.primaryLight,
                                  shape: BoxShape.circle,
                                  border: NeoBrutalism.border(width: 1.5),
                                ),
                                child: const Icon(Icons.phone_android_rounded, size: 24, color: Colors.black),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Perangkat Ini',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: NeoBrutalism.primary,
                                            borderRadius: BorderRadius.circular(6),
                                            border: NeoBrutalism.border(width: 1.0),
                                          ),
                                          child: Text(
                                            'Aktif',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sesi terenkripsi SHA-256 • Aktif sekarang',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: NeoBrutalism.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Danger Zone
                        Text(
                          'ZONA BERBAHAYA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: const Color(0xFFBA1A1A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => DeleteAccountDialog.show(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFBA1A1A), width: 2.0),
                              boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFDAD6),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: const Icon(
                                    Icons.delete_forever_rounded,
                                    size: 22,
                                    color: Color(0xFFBA1A1A),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hapus Akun Permanen',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFFBA1A1A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Hapus semua data dompet, riwayat, & preferensi',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: const Color(0xFF7F1D1D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: Color(0xFFBA1A1A),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
