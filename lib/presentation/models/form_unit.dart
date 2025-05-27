import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/utils/undefined.dart';

class FormUnit {

  FormUnit({
    required this.name,
    required this.factor,
  });

  factory FormUnit.fromUnit(Unit unit) {
    return FormUnit(
      name: unit.name,
      factor: unit.factor.toString(),
    );
  }
  final String name;
  final String factor;
  FormUnit Function({
    String name,
    String factor,
  }) get copyWith {
    return ({
      Object? name = undefined,
      Object? factor = undefined,
    }) {
      return FormUnit(
        name: name.or(this.name),
        factor: factor.or(this.factor),
      );
    };
  }

  // From FormUnit to Unit Data Entity
  Unit toUnit(int productId) {
    return Unit(
      name: name,
      productId: productId,
      factor: double.parse(factor),
    );
  }
}
