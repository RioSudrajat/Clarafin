import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/notification_model.dart';

final initialNotifications = <NotificationItem>[];

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
