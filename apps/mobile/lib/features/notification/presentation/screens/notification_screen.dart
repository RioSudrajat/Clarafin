import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_category_tabs.dart';
import '../widgets/notification_item_card.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(filteredNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

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
                    // Round Back Button
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
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 22,
                            color: NeoBrutalism.dark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Unread Badge
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Notifikasi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: NeoBrutalism.primary,
                                borderRadius: BorderRadius.circular(10),
                                border: NeoBrutalism.border(width: 1.5),
                                boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                              ),
                              child: Text(
                                '$unreadCount Baru',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Mark All Read Button
                    if (unreadCount > 0)
                      GestureDetector(
                        onTap: () {
                          ref.read(notificationsProvider.notifier).markAllAsRead();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: NeoBrutalism.primary,
                            borderRadius: BorderRadius.circular(12),
                            border: NeoBrutalism.border(width: 2.0),
                            boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                          ),
                          child: Text(
                            'Tandai Dibaca',
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
                  child: Column(
                    children: [
                      // Filter Tabs
                      const SizedBox(height: 14),
                      const NotificationCategoryTabs(),
                      const SizedBox(height: 10),

                      // Notification List / Empty State
                      Expanded(
                        child: notifications.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: NeoBrutalism.surfaceWarm,
                                      borderRadius: BorderRadius.circular(20),
                                      border: NeoBrutalism.border(width: 2.0),
                                      boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 68,
                                          height: 68,
                                          decoration: BoxDecoration(
                                            color: NeoBrutalism.primary,
                                            shape: BoxShape.circle,
                                            border: NeoBrutalism.border(width: 2.0),
                                            boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                                          ),
                                          child: const Icon(
                                            Icons.notifications_none_rounded,
                                            size: 34,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          'Belum Ada Notifikasi',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Pemberitahuan transaksi, pengingat sesi, serta promo penting akan tersusun rapi di sini.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: NeoBrutalism.textMuted,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                ref.read(notificationsProvider.notifier).loadSampleNotifications();
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: NeoBrutalism.primary,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: NeoBrutalism.border(width: 2.0),
                                                  boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                                                ),
                                                child: Text(
                                                  'Muat Notifikasi Contoh',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            GestureDetector(
                                              onTap: () => context.go('/home'),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: NeoBrutalism.border(width: 2.0),
                                                  boxShadow: NeoBrutalism.shadow(yOffset: 2.0),
                                                ),
                                                child: Text(
                                                  'Ke Beranda',
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
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: notifications.length,
                                itemBuilder: (context, index) {
                                  final item = notifications[index];
                                  return NotificationItemCard(item: item);
                                },
                              ),
                      ),
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
}
