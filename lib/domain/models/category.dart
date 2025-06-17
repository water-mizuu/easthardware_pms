import 'package:easthardware_pms/utils/undefined.dart';

class Category {
  const Category({
    this.id,
    required this.name,
    this.archiveStatus,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
  final int? id;
  final String name;
  final int? archiveStatus;

  Category Function({
    int? id,
    String name,
    int? archiveStatus,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? name = undefined,
      Object? archiveStatus = undefined,
    }) {
      return Category(
        id: id.or(this.id),
        name: name.or(this.name),
        archiveStatus: archiveStatus.or(this.archiveStatus),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      "name": name,
      "archive_status": archiveStatus ?? 0,
    };
  }
}
