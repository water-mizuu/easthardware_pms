import 'dart:convert';
import 'package:easthardware_pms/presentation/cubit/notifications/cubit/notification_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationLocalStorage {
  NotificationLocalStorage._();
  static final NotificationLocalStorage instance = NotificationLocalStorage._();

  List<ServerNotification> _notifications = [];
  List<ServerNotification> get notifications => List.unmodifiable(_notifications);

  static const String _storageKey = 'app_notifications';

  /// Initializes the notification manager, loading saved notifications
  Future<void> initialize() async {
    await _loadFromStorage();
  }

  /// Loads notifications from SharedPreferences
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      final jsonList = jsonDecode(jsonString) as List;
      _notifications = jsonList
          .map((item) => ServerNotification.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  }

  /// Saves current notifications to SharedPreferences
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_notifications
        .map((n) => {
              'id': n.id,
              'title': n.title,
              'message': n.message,
              'path': n.path,
              'time': n.time.toIso8601String(),
              'isRead': n.isRead,
              'type': n.type.value,
            })
        .toList());

    await prefs.setString(_storageKey, jsonString);
  }

  Future<List<ServerNotification>> getNotifications() async {
    return notifications;
  }

  Future<ServerNotification> addNotification({
    required String title,
    required String message,
    required String path,
    NotificationType type = NotificationType.info,
  }) async {
    // Create a new notification with a unique ID
    final notification = ServerNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      time: DateTime.now(),
      message: message,
      path: path,
      isRead: false,
      type: type,
    );

    _notifications.add(notification);
    await _saveToStorage();
    return notification;
  }

  Future<void> markAsRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveToStorage();
    }
  }

  Future<void> deleteNotification(int id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveToStorage();
  }

  Future<void> deleteAllNotifications() async {
    _notifications.clear();
    await _saveToStorage();
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _saveToStorage();
  }
}
