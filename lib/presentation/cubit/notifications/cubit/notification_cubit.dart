import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:easthardware_pms/domain/backend/utils/notification_server_proxy.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:fluent_ui/fluent_ui.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit(
    webSocketCustomChannel,
    super.initialState,
  ) : _proxy = webSocketCustomChannel != null
            ? NotificationServerProxy(Server(webSocketCustomChannel.channel))
            : null;

  final NotificationServerProxy? _proxy;

  void addNotificationFromServer(ServerNotification notification) {
    switch (notification.type) {
      case NotificationType.info:
        showNotification(
          title: notification.title,
          message: notification.message,
          severity: InfoBarSeverity.info,
        );
        break;
      case NotificationType.error:
        showNotification(
          title: notification.title,
          message: notification.message,
          severity: InfoBarSeverity.warning,
        );
        break;
      case NotificationType.warning:
        showNotification(
          title: notification.title,
          message: notification.message,
          severity: InfoBarSeverity.warning,
        );
        break;
      case NotificationType.success:
    }
    final notifications = [...state.notifications, notification];
    emit(state.copyWith(notifications: notifications));
  }

  // Keep client-side only implementations as requested
  Future<void> markAsRead(int id) async {
    final notifications = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    emit(state.copyWith(notifications: notifications));
  }

  Future<void> deleteNotification(int id) async {
    final notifications = state.notifications.where((n) => n.id != id).toList();
    emit(state.copyWith(notifications: notifications));
  }

  Future<void> deleteAllNotifications() async {
    emit(state.copyWith(notifications: []));
  }

  Future<void> markAllAsRead() async {
    final notifications = state.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();
    emit(state.copyWith(notifications: notifications));
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String path,
    NotificationType type = NotificationType.info,
  }) async {
    if (_proxy == null) return;

    await _proxy.addNotification(
      title: title,
      message: message,
      path: path,
      type: type,
    );

    /// WARNING: WE DO NOT UPDATE THE STATE HERE, AS THE CHANGE WILL FORCE THE STATE
    /// OF THE ENTIRE CUBIT TO REBUILD.
  }
}
