import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notification_item.dart';

final notificationsUserProvider =
    StateNotifierProvider<NotificationsController, List<NotificationItem>>(
        (ref) {
  return NotificationsController();
});

final notificationsAdminProvider =
    StateNotifierProvider<NotificationsController, List<NotificationItem>>(
        (ref) {
  return NotificationsController();
});

class NotificationsController extends StateNotifier<List<NotificationItem>> {
  NotificationsController() : super(const []);

  void addNotification(String title, String body) {
    final item = NotificationItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );
    state = [item, ...state];
  }

  void markAllRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }
}
