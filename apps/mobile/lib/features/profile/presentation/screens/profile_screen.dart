import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/currency_selector_bottom_sheet.dart';
import '../widgets/language_selector_bottom_sheet.dart';
import '../widgets/privacy_policy_bottom_sheet.dart';
import '../widgets/profile_logout_dialog.dart';
import '../widgets/profile_menu_group.dart';
import '../widgets/profile_stats_bento.dart';
import '../widgets/profile_user_card.dart';
import '../widgets/terms_conditions_bottom_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Pinned Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2.0),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: NeoBrutalism.circleDecoration(
                        backgroundColor: Colors.white,
                        shadowOffset: 2,
                        borderWidth: 2,
                      ),
                      child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Profil & Pengaturan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Card
                    ProfileUserCard(profile: profile),
                    const SizedBox(height: 14),

                    // Stats Bento
                    const ProfileStatsBento(),
                    const SizedBox(height: 18),

                    // Menu Group 1: Akun & Keamanan
                    ProfileMenuGroup(
                      groupTitle: 'AKUN & KEAMANAN',
                      items: [
                        ProfileMenuItemData(
                          icon: Icons.person_outline,
                          title: 'Edit Profil',
                          subtitle: 'Nama, telepon, template avatar Notion',
                          onTap: () => context.push('/profile/edit'),
                        ),
                        ProfileMenuItemData(
                          icon: Icons.lock_outline,
                          title: 'Keamanan & PIN',
                          subtitle: profile.biometricsEnabled ? 'Biometrik Aktif' : 'PIN Terpasang',
                          badgeText: profile.biometricsEnabled ? 'Aman' : null,
                          badgeColor: NeoBrutalism.lime,
                          onTap: () => context.push('/profile/security'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Menu Group 2: Preferensi Aplikasi
                    ProfileMenuGroup(
                      groupTitle: 'PREFERENSI APLIKASI',
                      items: [
                        ProfileMenuItemData(
                          icon: Icons.monetization_on_outlined,
                          title: 'Mata Uang Utama',
                          subtitle: 'Format nilai mata uang aplikasi',
                          badgeText: profile.currency,
                          badgeColor: NeoBrutalism.lime,
                          onTap: () => CurrencySelectorBottomSheet.show(context),
                        ),
                        ProfileMenuItemData(
                          icon: Icons.language_outlined,
                          title: 'Bahasa / Language',
                          subtitle: profile.language,
                          onTap: () => LanguageSelectorBottomSheet.show(context),
                        ),
                        ProfileMenuItemData(
                          icon: Icons.notifications_none,
                          title: 'Pengaturan Notifikasi',
                          subtitle: 'Transaksi, promo, jadwal sesi',
                          onTap: () => context.push('/profile/notifications'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Menu Group 3: Data & Privasi
                    ProfileMenuGroup(
                      groupTitle: 'DATA & PRIVASI',
                      items: [
                        ProfileMenuItemData(
                          icon: Icons.file_download_outlined,
                          title: 'Ekspor Data Finansial',
                          subtitle: 'Unduh laporan transaksi (PDF / CSV)',
                          onTap: () => context.push('/export'),
                        ),
                        ProfileMenuItemData(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Kebijakan Privasi',
                          subtitle: 'Enkripsi AES-256 & perlindungan data',
                          onTap: () => PrivacyPolicyBottomSheet.show(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Menu Group 4: Informasi & Bantuan
                    ProfileMenuGroup(
                      groupTitle: 'INFORMASI & DUKUNGAN',
                      items: [
                        ProfileMenuItemData(
                          icon: Icons.gavel_outlined,
                          title: 'Syarat & Ketentuan',
                          subtitle: 'Ketentuan layanan & disclaimer finansial',
                          onTap: () => TermsConditionsBottomSheet.show(context),
                        ),
                        ProfileMenuItemData(
                          icon: Icons.help_outline,
                          title: 'Pusat Bantuan & CS',
                          subtitle: 'FAQ dan layanan pelanggan 24/7',
                          onTap: () => context.push('/profile/support'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Logout Button
                    GestureDetector(
                      onTap: () => ProfileLogoutDialog.show(context),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(0, 2.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, size: 18, color: Color(0xFFBA1A1A)),
                            const SizedBox(width: 8),
                            Text(
                              'Keluar dari Akun',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFBA1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // App Version Footer
                    Text(
                      'Clarafin Mobile v1.2.0 • Build 2026',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
