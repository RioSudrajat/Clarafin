import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/neo_brutalism_decorations.dart';
import '../../domain/models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationItemCard extends ConsumerWidget {
  final NotificationItem item;

  const NotificationItemCard({
    super.key,
    required this.item,
  });

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}h lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.konsultasi:
        return NeoBrutalism.mint;
      case NotificationCategory.transaksi:
        return NeoBrutalism.primary;
      case NotificationCategory.promo:
        return NeoBrutalism.yellow;
      case NotificationCategory.sistem:
        return NeoBrutalism.lavender;
      case NotificationCategory.all:
        return NeoBrutalism.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = _getCategoryColor(item.category);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(notificationsProvider.notifier).deleteNotification(item.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: NeoBrutalism.coral,
          borderRadius: BorderRadius.circular(16),
          border: NeoBrutalism.border(width: 2.0),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.black, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : NeoBrutalism.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: NeoBrutalism.border(width: 2.0),
          boxShadow: NeoBrutalism.shadow(yOffset: 3.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ref.read(notificationsProvider.notifier).markAsRead(item.id);
            if (item.actionRoute != null) {
              context.push(item.actionRoute!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Icon Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                        border: NeoBrutalism.border(width: 1.5),
                        boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                      ),
                      child: Icon(
                        item.category.icon,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Timestamp
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              if (!item.isRead) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: NeoBrutalism.primary,
                                    borderRadius: BorderRadius.circular(8),
                                    border: NeoBrutalism.border(width: 1.2),
                                  ),
                                  child: Text(
                                    'BARU',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatRelativeTime(item.timestamp),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: NeoBrutalism.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Message Body
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Text(
                    item.message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),

                // Action Button (if any)
                if (item.actionLabel != null && item.actionRoute != null) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(notificationsProvider.notifier).markAsRead(item.id);
                        context.push(item.actionRoute!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: NeoBrutalism.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: NeoBrutalism.border(width: 1.5),
                          boxShadow: NeoBrutalism.shadow(yOffset: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.actionLabel!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
