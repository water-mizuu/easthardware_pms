part of 'notification_cubit.dart';

enum NotificationType {
  info('info'),
  warning('warning'),
  error('error'),
  success('success');

  const NotificationType(this.value);
  final String value;
}

class ServerNotification {
  factory ServerNotification.fromJson(Map<String, dynamic> json) {
    return ServerNotification(
      time: DateTime.parse(json['time'] as String),
      message: json['message'] as String,
      path: json['path'] as String,
      id: json['id'] as int,
      isRead: json['isRead'] as bool? ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.value == json['type'] as String,
        orElse: () => NotificationType.info,
      ),
    );
  }

  const ServerNotification({
    required this.time,
    required this.message,
    required this.path,
    required this.id,
    this.isRead = false,
    this.type = NotificationType.info,
  });

  final DateTime time;
  final String message;
  final String path;
  final int id;
  final bool isRead;
  final NotificationType type;

  @override
  String toString() {
    return 'Notification(time: $time, message: $message, path: $path, id: $id, isRead: $isRead, type: $type)';
  }

  ServerNotification Function({
    DateTime? time,
    String? message,
    String? path,
    int? id,
    bool? isRead,
    NotificationType? type,
  }) get copyWith {
    return ({
      DateTime? time,
      String? message,
      String? path,
      int? id,
      bool? isRead,
      NotificationType? type,
    }) {
      return ServerNotification(
        time: time ?? this.time,
        message: message ?? this.message,
        path: path ?? this.path,
        id: id ?? this.id,
        isRead: isRead ?? this.isRead,
        type: type ?? this.type,
      );
    };
  }
}

final class NotificationState {
  const NotificationState({this.notifications = const []});

  final List<ServerNotification> notifications;
  NotificationState Function({List<ServerNotification>? notifications}) get copyWith {
    return ({List<ServerNotification>? notifications}) {
      return NotificationState(
        notifications: notifications ?? this.notifications,
      );
    };
  }
}
