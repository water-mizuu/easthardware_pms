import 'package:easthardware_pms/utils/undefined.dart';

class Category {
  final int? id;
  final String name;

  const Category({
    this.id,
    required this.name,
  });

  Category Function({
    int? id,
    String name,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? name = undefined,
    }) {
      return Category(
        id: id.or(this.id),
        name: name.or(this.name),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      "name": name,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
}
