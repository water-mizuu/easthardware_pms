import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/models/unit.dart';

abstract class DataCellFunctions {}

class InvoiceProductFunctions extends DataCellFunctions {
  InvoiceProductFunctions({
    required this.onProductSelected,
    required this.onDescriptionChanged,
    required this.onQuantityChanged,
    required this.onUnitSelected,
    required this.onRateChanged,
    required this.onAmountChanged,
  });

  final Function(Product value) onProductSelected;
  final Function(String value) onDescriptionChanged;
  final Function(double value) onQuantityChanged;
  final Function(Unit value) onUnitSelected;
  final Function(double value) onRateChanged;
  final Function(double value) onAmountChanged;
}
