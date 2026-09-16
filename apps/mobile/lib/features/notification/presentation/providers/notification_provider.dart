import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification_model.dart';

final initialNotifications = [
  NotificationItem(
    id: 'notif-1',
    title: 'Konsultasi Terkonfirmasi! 🎉',
    message: 'Sesi konsultasi portofolio dengan Budi Santoso, CFP dijadwalkan besok pukul 10:00 WIB.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    category: NotificationCategory.konsultasi,
    isRead: false,
    actionRoute: '/consult/chat',
    actionLabel: 'Masuk Sesi Chat',
  ),
  NotificationItem(
    id: 'notif-2',
    title: 'Gaji Bulanan Terdeteksi 💰',
    message: 'Pemasukan sebesar Rp 15.000.000 berhasil dicatat ke BCA Utama.',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    category: NotificationCategory.transaksi,
    isRead: false,
    actionRoute: '/transaction/history',
    actionLabel: 'Lihat Mutasi',
  ),
  NotificationItem(
    id: 'notif-3',
    title: 'Voucher Konsultasi Diskon 50% 🏷️',
    message: 'Gunakan kode promo FINPRO50 untuk hemat hingga Rp 150.000 sesi konsultasi pertama Anda.',
    timestamp: DateTime.now().subtract(const Duration(hours: 6)),
    category: NotificationCategory.promo,
    isRead: false,
    actionRoute: '/vouchers',
    actionLabel: 'Klaim Kupon',
  ),
  NotificationItem(
    id: 'notif-4',
    title: 'Tagihan WiFi Mendekati Jatuh Tempo ⚠️',
    message: 'Tagihan Indihome sebesar Rp 385.000 jatuh tempo dalam 3 hari.',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    category: NotificationCategory.transaksi,
    isRead: true,
    actionRoute: '/budget',
    actionLabel: 'Lihat Tagihan',
  ),
  NotificationItem(
    id: 'notif-5',
    title: 'Pembaruan Fitur: Skor Finansial 🚀',
    message: 'Sekarang Anda dapat melihat analisis 4 rasio kesehatan finansial secara berkala di tab Home.',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    category: NotificationCategory.sistem,
    isRead: true,
    actionRoute: '/score',
    actionLabel: 'Cek Skor Saya',
  ),
  NotificationItem(
    id: 'notif-6',
    title: 'Target Tabungan "Emergency Fund" 80% 🎯',
    message: 'Hebat! Anda tinggal sedikit lagi mencapai target dana darurat Rp 25.000.000.',
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
    category: NotificationCategory.transaksi,
    isRead: true,
    actionRoute: '/budget',
    actionLabel: 'Lihat Goals',
  ),
];

class NotificationNotifier extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() {
    return initialNotifications;
  }

  void markAsRead(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final item in state) item.copyWith(isRead: true),
    ];
  }

  void deleteNotification(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void addNotification(NotificationItem item) {
    state = [item, ...state];
  }
}

final notificationsProvider =
    NotifierProvider<NotificationNotifier, List<NotificationItem>>(
  NotificationNotifier.new,
);

class NotificationCategoryFilterNotifier extends Notifier<NotificationCategory> {
  @override
  NotificationCategory build() => NotificationCategory.all;

  void selectCategory(NotificationCategory category) => state = category;
}

final selectedCategoryFilterProvider =
    NotifierProvider<NotificationCategoryFilterNotifier, NotificationCategory>(() {
  return NotificationCategoryFilterNotifier();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.where((item) => !item.isRead).length;
});

final filteredNotificationsProvider = Provider<List<NotificationItem>>((ref) {
  final notifs = ref.watch(notificationsProvider);
  final category = ref.watch(selectedCategoryFilterProvider);

  if (category == NotificationCategory.all) {
    return notifs;
  }
  return notifs.where((item) => item.category == category).toList();
});
