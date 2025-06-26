import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:uuid/uuid.dart';

class UserLog {
  UserLog({
    String? uid,
    this.id,
    required this.userId,
    required this.event,
    required this.eventTime,
  }) : uid = uid ?? const Uuid().v4();

  factory UserLog.login({
    required User user,
    DateTime? eventTime,
  }) {
    final logEvent = "User '${user.username}' logged in";
    final logDateTime = eventTime ?? DateTime.now();
    final userLog = UserLog(
      userId: user.id!,
      event: logEvent,
      eventTime: logDateTime,
    );

    return userLog;
  }

  factory UserLog.logout({
    required User user,
    DateTime? eventTime,
  }) {
    final logEvent = "User '${user.username}' logged out";
    final logDateTime = eventTime ?? DateTime.now();
    final userLog = UserLog(
      userId: user.id!,
      event: logEvent,
      eventTime: logDateTime,
    );

    return userLog;
  }

  factory UserLog.create({
    required User user,
    required String item,
    DateTime? eventTime,
  }) {
    final logEvent = "User '${user.username}' created $item";
    final logDateTime = eventTime ?? DateTime.now();
    final userLog = UserLog(
      userId: user.id!,
      event: logEvent,
      eventTime: logDateTime,
    );

    return userLog;
  }

  factory UserLog.update({
    required User user,
    required String item,
    DateTime? eventTime,
  }) {
    final logEvent = "User '${user.username}' updated $item";
    final logDateTime = eventTime ?? DateTime.now();
    final userLog = UserLog(
      userId: user.id!,
      event: logEvent,
      eventTime: logDateTime,
    );

    return userLog;
  }

  factory UserLog.archive({
    required User user,
    required String item,
    DateTime? eventTime,
  }) {
    final logEvent = "Archived $item";
    final logDateTime = eventTime ?? DateTime.now();
    final userLog = UserLog(
      userId: user.id!,
      event: logEvent,
      eventTime: logDateTime,
    );

    return userLog;
  }

  factory UserLog.backupDatabase({
    required User user,
    DateTime? eventTime,
  }) {
    final logEvent = "User '${user.username}' created a backup";
    final logDateTime = eventTime ?? DateTime.now();
    final userLog = UserLog(
      userId: user.id!,
      event: logEvent,
      eventTime: logDateTime,
    );

    return userLog;
  }

  factory UserLog.restoreDatabase({
    required User user,
    DateTime? eventTime,
  }) {
    final logEvent = "User '${user.username}' restored a backup";
    final logDateTime = eventTime ?? DateTime.now();
    final userLog = UserLog(
      userId: user.id!,
      event: logEvent,
      eventTime: logDateTime,
    );

    return userLog;
  }

  factory UserLog.fromMap(Map<String, dynamic> map) {
    return UserLog(
      id: map['id'],
      uid: map['uid'],
      userId: map['user_id'],
      event: map['event'],
      eventTime: DateTime.parse(map['event_time']),
    );
  }
  final int? id;
  final String uid;
  final int userId;
  final String event;
  final DateTime eventTime;

  UserLog Function({
    int? id,
    String? uid,
    int? userId,
    String? event,
    DateTime? eventTime,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? uid = undefined,
      Object? userId = undefined,
      Object? event = undefined,
      Object? eventTime = undefined,
    }) {
      return UserLog(
        id: id.or(this.id),
        uid: uid.or(this.uid),
        userId: userId.or(this.userId),
        event: event.or(this.event),
        eventTime: eventTime.or(this.eventTime),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uid': uid,
      'user_id': userId,
      'event': event,
      'event_time': eventTime.toIso8601String(),
    };
  }
}
