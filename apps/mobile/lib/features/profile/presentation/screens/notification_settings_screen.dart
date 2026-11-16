import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/user_profile_model.dart';
import '../providers/user_profile_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);

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
                      'Pengaturan Notifikasi',
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
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    physics: const ClampingScrollPhysics(),
                    children: [
                      // Highlight Info Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: NeoBrutalism.surfaceWarm,
                          borderRadius: BorderRadius.circular(16),
                          border: NeoBrutalism.border(width: 2.0),
                          boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: NeoBrutalism.primary,
                                shape: BoxShape.circle,
                                border: NeoBrutalism.border(width: 1.5),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pusat Notifikasi Aktif',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kelola saluran pengingat agar keuangan dan sesi tetap terkontrol tanpa gangguan berlebih.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: NeoBrutalism.textMuted,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Daily Ritual Top Card (2-way sync with Onboarding Step 6)
                      _buildDailyRitualCard(context, profile, notifier),
                      const SizedBox(height: 12),

                      _buildToggleCard(
                        title: 'Pemberitahuan Transaksi',
                        description: 'Notifikasi instan saat pengeluaran atau pemasukan baru tercatat',
                        value: profile.notificationsEnabled,
                        onChanged: (val) => notifier.toggleNotifications(val),
                        icon: Icons.receipt_long_outlined,
                        badgeColor: NeoBrutalism.primaryLight,
                      ),
                      const SizedBox(height: 12),
                      _buildToggleCard(
                        title: 'Jadwal & Sesi Konsultasi',
                        description: 'Pengingat H-1 dan 15 menit sebelum sesi obrolan dengan pakar',
                        value: profile.sessionRemindersEnabled,
                        onChanged: (val) => notifier.toggleSessionReminders(val),
                        icon: Icons.calendar_month_outlined,
                        badgeColor: NeoBrutalism.mint,
                      ),
                      const SizedBox(height: 12),
                      _buildToggleCard(
                        title: 'Pengingat Jatuh Tempo Tagihan',
                        description: 'Peringatan H-3 sebelum tagihan berkala jatuh tempo',
                        value: profile.billRemindersEnabled,
                        onChanged: (val) => notifier.toggleBillReminders(val),
                        icon: Icons.warning_amber_outlined,
                        badgeColor: NeoBrutalism.surfaceWarm,
                      ),
                      const SizedBox(height: 12),
                      _buildToggleCard(
                        title: 'Promo & Kupon Eksklusif',
                        description: 'Voucher diskon sesi konsultasi dan penawaran mitra finansial',
                        value: profile.promoAlertsEnabled,
                        onChanged: (val) => notifier.togglePromoAlerts(val),
                        icon: Icons.local_offer_outlined,
                        badgeColor: NeoBrutalism.lavender,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRitualCard(
    BuildContext context,
    UserProfile profile,
    UserProfileNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoBrutalism.mint,
        borderRadius: BorderRadius.circular(16),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: NeoBrutalism.lime,
                  borderRadius: BorderRadius.circular(10),
                  border: NeoBrutalism.border(width: 1.5),
                ),
                child: const Icon(Icons.nightlight_round, size: 22, color: NeoBrutalism.dark),
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
                          'PENGINGAT TUTUP HARI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: NeoBrutalism.teal,
                          ),
                        ),
                        Switch(
                          value: profile.dailyReminderEnabled,
                          onChanged: (val) {
                            notifier.setDailyReminder(val, profile.dailyReminderTime);
                          },
                          activeThumbColor: NeoBrutalism.lime,
                          activeTrackColor: NeoBrutalism.dark,
                        ),
                      ],
                    ),
                    Text(
                      'Satu menit tiap malam untuk mencatat pengeluaran sebelum istirahat.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: NeoBrutalism.dark,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final parts = profile.dailyReminderTime.split(':');
              final initialTime = TimeOfDay(
                hour: int.tryParse(parts[0]) ?? 20,
                minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
              );
              final picked = await showTimePicker(
                context: context,
                initialTime: initialTime,
              );
              if (picked != null) {
                final hourStr = picked.hour.toString().padLeft(2, '0');
                final minStr = picked.minute.toString().padLeft(2, '0');
                notifier.setDailyReminder(profile.dailyReminderEnabled, '$hourStr:$minStr');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: NeoBrutalism.border(width: 1.5),
                boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_filled_rounded, size: 16, color: NeoBrutalism.dark),
                  const SizedBox(width: 8),
                  Text(
                    '⏰ ${profile.dailyReminderTime} WIB — Ubah Jam',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: NeoBrutalism.dark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: NeoBrutalism.border(width: 2.0),
        boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: NeoBrutalism.border(width: 1.5),
            ),
            child: Icon(icon, size: 20, color: Colors.black),
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
                    color: NeoBrutalism.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.black,
            activeTrackColor: NeoBrutalism.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
