import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/user_profile_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);

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
                    'Pengaturan Notifikasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Toggle Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildToggleCard(
                    title: 'Pemberitahuan Transaksi',
                    description: 'Notifikasi instan saat pengeluaran atau pemasukan baru tercatat',
                    value: profile.notificationsEnabled,
                    onChanged: (_) => notifier.toggleNotifications(),
                    icon: Icons.receipt_long_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    title: 'Jadwal & Sesi Konsultasi',
                    description: 'Pengingat H-1 dan 15 menit sebelum sesi obrolan dengan pakar',
                    value: true,
                    onChanged: (_) {},
                    icon: Icons.calendar_month_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    title: 'Pengingat Jatuh Tempo Tagihan',
                    description: 'Peringatan H-3 sebelum tagihan berkala jatuh tempo',
                    value: true,
                    onChanged: (_) {},
                    icon: Icons.warning_amber_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    title: 'Promo & Kupon Eksklusif',
                    description: 'Voucher diskon sesi konsultasi dan penawaran mitra finansial',
                    value: profile.promoAlertsEnabled,
                    onChanged: (_) => notifier.togglePromoAlerts(),
                    icon: Icons.local_offer_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, size: 18, color: Colors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 1.4,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.black,
            activeTrackColor: NeoBrutalism.lime,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
