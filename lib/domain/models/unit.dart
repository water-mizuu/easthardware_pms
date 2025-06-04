import 'package:easthardware_pms/utils/undefined.dart';

class Unit {
  Unit({
    this.id,
    this.productId,
    required this.name,
    required this.mainQuantity,
    required this.unitQuantity,
  });

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map.getCast<int>('id'),
      productId: map.getCast<int>('product_id'),
      name: map.getCast<String>('name'),
      mainQuantity: map.getCast<int>('main_quantity'),
      unitQuantity: map.getCast<int>('unit_quantity'),
    );
  }
  final int? id;
  final int? productId;
  final String name;
  final int mainQuantity;
  final int unitQuantity;

  Unit Function({
    int? id,
    int? productId,
    String name,
    int mainQuantity,
    int unitQuantity,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? productId = undefined,
      Object? name = undefined,
      Object? mainQuantity = undefined,
      Object? unitQuantity = undefined,
    }) {
      return Unit(
        id: id.or(this.id),
        productId: productId.or(this.productId),
        name: name.or(this.name),
        mainQuantity: mainQuantity.or(this.mainQuantity),
        unitQuantity: unitQuantity.or(this.unitQuantity),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'main_quantity': mainQuantity,
      'unit_quantity': unitQuantity,
    };
  }
}

extension<K> on Map<K, dynamic> {
  T getCast<T>(K key) {
    final value = this[key];

    if (value is T) {
      return value;
    } else {
      throw Exception(
          'Value for key $key is not of type $T, but is of ${value.runtimeType}');
    }
  }
}
