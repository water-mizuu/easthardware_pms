import 'package:easthardware_pms/utils/undefined.dart';

class Unit {
  final int? id;
  final int? productId;
  final String name;
  final double factor;

  Unit({
    this.id,
    this.productId,
    required this.name,
    required this.factor,
  });

  Unit Function({
    int? id,
    int? productId,
    String name,
    double factor,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? productId = undefined,
      Object? name = undefined,
      Object? factor = undefined,
    }) {
      return Unit(
        id: id.or(this.id),
        productId: productId.or(this.productId),
        name: name.or(this.name),
        factor: factor.or(this.factor),
      );
    };
  }

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      name: map['name'] as String,
      factor: map['conversion_factor'] as double,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'conversion_factor': factor,
    };
  }
}
