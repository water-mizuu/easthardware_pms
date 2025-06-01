import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

class FormUnit with EquatableMixin {
  const FormUnit({
    required this.name,
    required this.unitQuantity,
    required this.mainQuantity,
  });

  /// Factor should be defined as unit per main.
  ///   A factor of 30 means that for every 30 (secondary) unit, there is 1 (main) unit.
  factory FormUnit.fromUnit(Unit unit) {
    return FormUnit(
      name: unit.name,
      unitQuantity: unit.unitQuantity.toString(),
      mainQuantity: unit.mainQuantity.toString(),
    );
  }

  final String name;
  final String unitQuantity;
  final String mainQuantity;

  FormUnit Function({
    String name,
    String unitQuantity,
    String mainQuantity,
  }) get copyWith {
    return ({
      Object? name = undefined,
      Object? unitQuantity = undefined,
      Object? mainQuantity = undefined,
    }) {
      return FormUnit(
        name: name.or(this.name),
        unitQuantity: unitQuantity.or(this.unitQuantity),
        mainQuantity: mainQuantity.or(this.mainQuantity),
      );
    };
  }

  // From FormUnit to Unit Data Entity
  Unit toUnit(int productId) {
    final unitQuantity = int.parse(this.unitQuantity);
    final mainQuantity = int.parse(this.mainQuantity);

    return Unit(
      name: name,
      productId: productId,
      mainQuantity: mainQuantity,
      unitQuantity: unitQuantity,
    );
  }

  @override
  List<Object?> get props => [name, unitQuantity, mainQuantity];
}
