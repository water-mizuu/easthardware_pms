import 'package:easthardware_pms/utils/undefined.dart';

class PaymentMethod {
  const PaymentMethod({
    this.id,
    required this.name,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  final int? id;
  final String name;

  PaymentMethod Function({
    int? id,
    String name,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? name = undefined,
    }) {
      return PaymentMethod(
        id: id.or(this.id),
        name: name.or(this.name),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
