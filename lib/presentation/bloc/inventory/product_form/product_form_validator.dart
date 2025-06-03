mixin ProductFormValidator {
  String? validateProductName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Product name cannot be empty";
    }
    return null;
  }

  String? validateProductCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Product category cannot be empty";
    }
    return null;
  }

  String? validateProductCriticalLevel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Critical level cannot be empty";
    }
    final criticalLevel = double.tryParse(value);
    if (criticalLevel == null || criticalLevel < 0) {
      return "Critical level must be a non-negative number";
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

  String? validateSecondaryUnitName({required String? name, required List<String> existingNames}) {
    if (existingNames.last == name) {
      return "Secondary unit cannot be the same as the primary unit.";
    }
    if (name == null || name.isEmpty) {
      return "Alternate unit name cannot be empty.";
    }

    if (existingNames.contains(name)) {
      return "Secondary unit already exists.";
    }
    return null;
  }

  String? validateMainUnitCount({
    required String? count,
  }) {
    if (count == null || count.trim().isEmpty) {
      return "Main equivalent cannot be empty.";
    }
    final conversionFactor = double.tryParse(count);
    if (conversionFactor == null || conversionFactor <= 0) {
      return "Main equivalent must be a positive number.";
    }

    return null;
  }

  String? validateSecondaryUnitCount({
    required String? count,
  }) {
    if (count == null || count.trim().isEmpty) {
      return "Secondary unit cannot be empty.";
    }
    final conversionFactor = int.tryParse(count);
    if (conversionFactor == null || conversionFactor <= 0) {
      return "Secondary unit must be a positive number.";
    }

    return null;
  }

  String? validateDeadStockThreshold(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final deadStockThreshold = double.tryParse(value);
    if (deadStockThreshold == null || deadStockThreshold < 0) {
      return "Dead stock threshold must be a non-negative number";
    }
    return null;
  }

  String? validateFastMovingThreshold(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final fastMovingThreshold = double.tryParse(value);
    if (fastMovingThreshold == null || fastMovingThreshold < 0) {
      return "Fast moving threshold must be a non-negative number";
    }
    return null;
  }
}
