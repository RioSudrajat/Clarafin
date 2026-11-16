import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/currency_selector_bottom_sheet.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/language_selector_bottom_sheet.dart';
import '../widgets/privacy_policy_bottom_sheet.dart';
import '../widgets/profile_logout_dialog.dart';
import '../widgets/profile_menu_group.dart';
import '../widgets/profile_saas_plan_card.dart';
import '../widgets/profile_gmail_sync_card.dart';
import '../widgets/profile_stats_bento.dart';
import '../widgets/profile_user_card.dart';
import '../widgets/terms_conditions_bottom_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
            // Pinned Neo-Brutalism Header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
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
                      'Profil & Pengaturan',
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
                      children: [
                        // Profile Card
                        ProfileUserCard(profile: profile),
                        const SizedBox(height: 14),

                        // SaaS Plan & AI Quota
                        const ProfileSaasPlanCard(),
                        const SizedBox(height: 12),

                        // Gmail Auto-Sync
                        const ProfileGmailSyncCard(),
                        const SizedBox(height: 14),

                        // Stats Bento (Dynamic & Interactive)
                        const ProfileStatsBento(),
                        const SizedBox(height: 18),

                        // Menu Group 1: Akun & Keamanan
                        ProfileMenuGroup(
                          groupTitle: 'AKUN & KEAMANAN',
                          items: [
                            ProfileMenuItemData(
                              icon: Icons.person_outline_rounded,
                              title: 'Edit Profil',
                              subtitle: 'Nama, telepon, avatar profil',
                              onTap: () => context.push('/profile/edit'),
                            ),
                            ProfileMenuItemData(
                              icon: Icons.lock_outline_rounded,
                              title: 'Keamanan & PIN',
                              subtitle: profile.biometricsEnabled ? 'Biometrik Aktif' : 'PIN Terpasang',
                              badgeText: profile.biometricsEnabled ? 'Aman' : null,
                              badgeColor: NeoBrutalism.primary,
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
                              badgeColor: NeoBrutalism.primary,
                              onTap: () => CurrencySelectorBottomSheet.show(context),
                            ),
                            ProfileMenuItemData(
                              icon: Icons.language_outlined,
                              title: 'Bahasa / Language',
                              subtitle: profile.language,
                              onTap: () => LanguageSelectorBottomSheet.show(context),
                            ),
                            ProfileMenuItemData(
                              icon: Icons.notifications_none_rounded,
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
                              icon: Icons.help_outline_rounded,
                              title: 'Pusat Bantuan & CS',
                              subtitle: 'FAQ dan layanan pelanggan 24/7',
                              onTap: () => context.push('/profile/support'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Logout Button
                        GestureDetector(
                          onTap: () => ProfileLogoutDialog.show(context, ref),
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: NeoBrutalism.coral,
                              borderRadius: BorderRadius.circular(14),
                              border: NeoBrutalism.border(width: 2.0),
                              boxShadow: NeoBrutalism.shadow(yOffset: 2.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFBA1A1A)),
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
                        const SizedBox(height: 12),

                        // Delete Account Link
                        GestureDetector(
                          onTap: () => DeleteAccountDialog.show(context, ref),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                                const SizedBox(width: 6),
                                Text(
                                  'Hapus Akun & Data Permanen',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFDC2626),
                                    decoration: TextDecoration.underline,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
