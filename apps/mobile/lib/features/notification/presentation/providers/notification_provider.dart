import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/notification_model.dart';

List<NotificationItem> getDefaultSampleNotifications() {
  final now = DateTime.now();
  return [
    NotificationItem(
      id: 'notif_session_1',
      title: 'Jadwal Konsultasi Terkonfirmasi',
      message: 'Sesi perencanaan keuangan bersama Budi Santoso, CFP® dijadwalkan besok pukul 10:00 WIB.',
      timestamp: now.subtract(const Duration(hours: 2)),
      category: NotificationCategory.konsultasi,
      isRead: false,
      actionRoute: '/session',
      actionLabel: 'Lihat Sesi',
    ),
    NotificationItem(
      id: 'notif_tx_1',
      title: 'Pengeluaran Dicatat',
      message: 'Pengeluaran "Kopi & Makan Siang" sebesar Rp 45.000 berhasil dicatat di Dompet Utama.',
      timestamp: now.subtract(const Duration(hours: 5)),
      category: NotificationCategory.transaksi,
      isRead: false,
      actionRoute: '/budget',
      actionLabel: 'Cek Budget',
    ),
    NotificationItem(
      id: 'notif_promo_1',
      title: 'Promo Spesial Sesi Pertama',
      message: 'Gunakan kupon CLARAFIRST untuk potongan 50% konsultasi perdana bersama praktisi bersertifikasi.',
      timestamp: now.subtract(const Duration(days: 1)),
      category: NotificationCategory.promo,
      isRead: true,
      actionRoute: '/consult',
      actionLabel: 'Pakai Kupon',
    ),
    NotificationItem(
      id: 'notif_system_1',
      title: 'Selamat Datang di Clarafin!',
      message: 'Mulai kelola dompetmu, tetapkan target tabungan, dan konsultasikan masa depan finansialmu.',
      timestamp: now.subtract(const Duration(days: 2)),
      category: NotificationCategory.sistem,
      isRead: true,
      actionRoute: '/home',
      actionLabel: 'Jelajahi',
    ),
  ];
}

class NotificationNotifier extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() {
    final userId = ref.watch(authProvider.select((s) => s.currentUser?.id));
    if (userId == null || userId.isEmpty) {
      return getDefaultSampleNotifications();
    }
    final stored = ref.read(localStorageServiceProvider).getNotifications(userId);
    if (stored.isNotEmpty) {
      return stored;
    }
    final samples = getDefaultSampleNotifications();
    ref.read(localStorageServiceProvider).saveNotifications(userId, samples);
    return samples;
  }

  void _persist() {
    final userId = ref.read(authProvider).currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      ref.read(localStorageServiceProvider).saveNotifications(userId, state);
    }
  }

  void markAsRead(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isRead: true) else item,
    ];
    _persist();
  }

  void markAllAsRead() {
    state = [
      for (final item in state) item.copyWith(isRead: true),
    ];
    _persist();
  }

  void deleteNotification(String id) {
    state = state.where((item) => item.id != id).toList();
    _persist();
  }

  void addNotification(NotificationItem item) {
    state = [item, ...state];
    _persist();
  }

  void loadSampleNotifications() {
    state = getDefaultSampleNotifications();
    _persist();
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
