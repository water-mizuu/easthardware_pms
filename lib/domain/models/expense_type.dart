import 'package:easthardware_pms/utils/undefined.dart';

class ExpenseType {

  ExpenseType({
    this.id,
    required this.name,
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
  ExpenseType Function({
    int? id,
    String name,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? name = undefined,
    }) {
      return ExpenseType(
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
}
