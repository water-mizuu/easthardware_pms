import 'package:easthardware_pms/utils/undefined.dart';

class ExpenseType {
  const ExpenseType({
    this.id,
    required this.name,
    this.archiveStatus,
  });

  //from map to object
  factory ExpenseType.fromMap(Map<String, dynamic> map) {
    return ExpenseType(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
  final int? id;
  final String name;
  final int? archiveStatus;
  ExpenseType Function({
    int? id,
    String name,
    int? archiveStatus,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? name = undefined,
      Object? archiveStatus = undefined,
    }) {
      return ExpenseType(
        id: id.or(this.id),
        name: name.or(this.name),
        archiveStatus: archiveStatus.or(this.archiveStatus),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      "id": id,
      "name": name,
      "archive_status": archiveStatus ?? 0,
    };
  }
}
