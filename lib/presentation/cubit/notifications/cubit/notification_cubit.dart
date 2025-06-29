import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:easthardware_pms/domain/backend/utils/notification_server_proxy.dart';

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
    final notifications = [...state.notifications, notification];
    emit(state.copyWith(notifications: notifications));
  }

  Future<void> loadNotifications() async {
    if (_proxy == null) return;
    final notifications = await _proxy.getNotifications();
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
    required String message,
    required String path,
    NotificationType type = NotificationType.info,
  }) async {
    if (_proxy == null) return;
    final notification = await _proxy.addNotification(
      message: message,
      path: path,
      type: type,
    );
    final notifications = [...state.notifications, notification];
    emit(state.copyWith(notifications: notifications));
  }
}
