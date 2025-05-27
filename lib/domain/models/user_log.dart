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
      'uid': uid,
      'user_id': userId,
      'event': event,
      'event_time': eventTime.toIso8601String(),
    };
  }
}
