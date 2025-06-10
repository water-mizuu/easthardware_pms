import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

class FormUnit with EquatableMixin {
  const FormUnit({
    required this.id,
    required this.name,
    required this.unitQuantity,
    required this.mainQuantity,
  });
  const FormUnit.empty()
      : id = null,
        name = const SecondaryUnitFormName(''),
        unitQuantity = const SecondaryUnitFormUnitQuantity(''),
        mainQuantity = const SecondaryUnitFormMainQuantity('');

  /// Factor should be defined as unit per main.
  ///   A factor of 30 means that for every 30 (secondary) unit, there is 1 (main) unit.
  factory FormUnit.fromUnit(Unit unit) {
    return FormUnit(
      id: unit.id,
      name: SecondaryUnitFormName(unit.name),
      unitQuantity: SecondaryUnitFormUnitQuantity(unit.unitQuantity.toString()),
      mainQuantity: SecondaryUnitFormMainQuantity(unit.mainQuantity.toString()),
    );
  }

  /// This should be not null for existing units, null for new units
  final int? id;
  final SecondaryUnitFormName name;
  final SecondaryUnitFormUnitQuantity unitQuantity;
  final SecondaryUnitFormMainQuantity mainQuantity;

  FormUnit Function({
    int? id,
    SecondaryUnitFormName name,
    SecondaryUnitFormUnitQuantity unitQuantity,
    SecondaryUnitFormMainQuantity mainQuantity,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? name = undefined,
      Object? unitQuantity = undefined,
      Object? mainQuantity = undefined,
    }) {
      return FormUnit(
        id: id.or(this.id),
        name: name.or(this.name),
        unitQuantity: unitQuantity.or(this.unitQuantity),
        mainQuantity: mainQuantity.or(this.mainQuantity),
      );
    };
  }

  // From FormUnit to Unit Data Entity
  Unit toUnit(int productId) {
    final unitQuantity = int.parse(this.unitQuantity.value);
    final mainQuantity = int.parse(this.mainQuantity.value);

    return Unit(
      id: id,
      name: name.value,
      productId: productId,
      mainQuantity: mainQuantity,
      unitQuantity: unitQuantity,
    );
  }

  @override
  List<Object?> get props => [id, name, unitQuantity, mainQuantity];
}

extension type const SecondaryUnitFormPart(String value) {
  bool get isEmpty => value.isEmpty;
  bool get isNotEmpty => value.isNotEmpty;

  String trim() => value.trim();
}
extension type const SecondaryUnitFormName(String value) implements SecondaryUnitFormPart {}
extension type const SecondaryUnitFormUnitQuantity(String value) implements SecondaryUnitFormPart {}
extension type const SecondaryUnitFormMainQuantity(String value) implements SecondaryUnitFormPart {}
