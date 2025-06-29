import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:easthardware_pms/presentation/cubit/notifications/cubit/notification_cubit.dart';

class NotificationServerProxy with ServerRedirect {
  NotificationServerProxy(this.server);

  @override
  final Server server;

  /// Get all notifications from the server
  Future<List<ServerNotification>> getNotifications() async {
    final notifications = await server.invokeMethod("get_notifications", []);
    return [
      for (final n in notifications as List<dynamic>)
        ServerNotification.fromJson(n as Map<String, dynamic>)
    ];
  }

  /// Add a new notification
  Future<ServerNotification> addNotification({
    required String message,
    required String path,
    NotificationType type = NotificationType.info,
  }) async {
    final notification = await server.invokeMethod(
      "add_notification",
      [message, path, type.value],
    );
    return ServerNotification.fromJson(notification as Map<String, dynamic>);
  }
}
