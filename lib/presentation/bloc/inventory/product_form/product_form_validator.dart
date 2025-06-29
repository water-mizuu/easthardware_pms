import 'package:easthardware_pms/presentation/models/form_unit.dart';

mixin ProductFormValidator {
  String? validateProductName(String? value, List<String> existingNames) {
    if (value == null || value.trim().isEmpty) {
      return "Product name cannot be empty";
    }
    if (existingNames.contains(value.trim())) {
      return "Product name already exists";
    }

    return null;
  }

  String? validateProductPrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Product price cannot be empty";
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return "Product price must be a non-negative number";
    }
    return null;
  }

  String? validateProductCost(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Product cost cannot be empty";
    }
    final cost = double.tryParse(value);
    if (cost == null || cost <= 0) {
      return "Product cost must be a non-negative number";
    }
    return null;
  }

  String? validateProductQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Product quantity cannot be empty";
    }
    final quantity = double.tryParse(value);
    if (quantity == null || quantity < 0) {
      return "Product quantity must be a non-negative number";
    }
    return null;
  }

  String? validateProductUnitName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Unit name cannot be empty.";
    }
    return null;
  }

  String? validateStockKeepingUnit(String? value, List<String> existingSKUs) {
    if (value == null || value.trim().isEmpty) {
      return "Stock Keeping Unit (SKU) cannot be empty.";
    }
    if (existingSKUs.contains(value.trim())) {
      return "SKU already exists.";
    }
    return null;
  }

  String? validateProductUnitFactor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Conversion factor cannot be empty.";
    }
    final factor = double.tryParse(value);
    if (factor == null || factor <= 0) {
      return "Factor must be a positive number.";
    }
    return null;
  }

  String? validateMinReorderDelay(String? value, int maxReorderDelay) {
    if (value == null || value.trim().isEmpty) {
      return "Minimum reorder delay cannot be empty.";
    }
    final delay = int.tryParse(value);
    if (delay == null || delay < 0) {
      return "Minimum reorder delay must be a non-negative integer.";
    }
    if (delay > maxReorderDelay) {
      return "Minimum reorder delay cannot be greater than maximum order delay.";
    }
    return null;
  }

  String? validateMaxReorderDelay(String? value, int minReorderDelay) {
    if (value == null || value.trim().isEmpty) {
      return "Maximum reorder delay cannot be empty.";
    }
    final delay = int.tryParse(value);
    if (delay == null || delay < 0) {
      return "Maximum reorder delay must be a non-negative integer.";
    }
    if (delay < minReorderDelay) {
      return "Maximum reorder delay cannot be less than minimum order delay.";
    }
    return null;
  }

  String? validateSecondaryUnitName({
    required SecondaryUnitFormName? name,
    required SecondaryUnitFormUnitQuantity? unitQuantity,
    required SecondaryUnitFormMainQuantity? mainQuantity,
    required List<String> existingNames,
  }) {
    /// Basically, if the secondary name is empty, unit quantity is empty,
    ///   and the main quantity is empty, we don't need to validate anything.
    /// It means that the secondary unit is not being used.
    if ((name == null || name.isEmpty) &&
        (unitQuantity == null || unitQuantity.isEmpty) &&
        (mainQuantity == null || mainQuantity.isEmpty)) {
      return null;
    }

    if (name == null || name.isEmpty) {
      return "Secondary unit name cannot be empty.";
    }

    if (existingNames.last == name.value) {
      return "Secondary unit cannot be the same as the primary unit.";
    }

    if (existingNames.contains(name.value)) {
      return "Secondary unit already exists.";
    }

    return null;
  }

  String? validateMainUnitQuantity({
    required SecondaryUnitFormName? secondaryName,
    required SecondaryUnitFormUnitQuantity? unitQuantity,
    required SecondaryUnitFormMainQuantity? mainQuantity,
  }) {
    /// Basically, if the secondary name is empty, unit quantity is empty,
    ///   and the main quantity is empty, we don't need to validate anything.
    /// It means that the secondary unit is not being used.
    if ((secondaryName == null || secondaryName.isEmpty) &&
        (unitQuantity == null || unitQuantity.isEmpty) &&
        (mainQuantity == null || mainQuantity.isEmpty)) {
      return null;
    }

    if (mainQuantity == null || mainQuantity.trim().isEmpty) {
      return "Main equivalent cannot be empty.";
    }

    final conversionFactor = double.tryParse(mainQuantity.value);
    if (conversionFactor == null || conversionFactor <= 0) {
      return "Main equivalent must be a positive number.";
    }

    return null;
  }

  String? validateSecondaryUnitQuantity({
    required SecondaryUnitFormName? secondaryName,
    required SecondaryUnitFormUnitQuantity? unitQuantity,
    required SecondaryUnitFormMainQuantity? mainQuantity,
  }) {
    /// Basically, if the secondary name is empty,
    if ((secondaryName == null || secondaryName.isEmpty) &&
        (unitQuantity == null || unitQuantity.isEmpty) &&
        (mainQuantity == null || mainQuantity.isEmpty)) {
      return null;
    }

    if (unitQuantity == null || unitQuantity.trim().isEmpty) {
      return "Secondary unit cannot be empty.";
    }

    final conversionFactor = int.tryParse(unitQuantity.value);
    if (conversionFactor == null || conversionFactor <= 0) {
      return "Secondary unit must be a positive number.";
    }

    return null;
  }

  String? validateDeadStockThreshold(String? value) {
    final deadStockThreshold = double.tryParse(value?.trim() ?? '');
    if (deadStockThreshold == null || deadStockThreshold < 0) {
      return "Dead stock threshold must be a non-negative number";
    }
    return null;
  }

  String? validateFastMovingThreshold(String? value) {
    final fastMovingThreshold = double.tryParse(value?.trim() ?? '');
    if (fastMovingThreshold == null || fastMovingThreshold < 0) {
      return "Fast moving threshold must be a non-negative number";
    }
    return null;
  }
}
