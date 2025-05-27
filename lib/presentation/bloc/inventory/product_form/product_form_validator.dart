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
    final double? criticalLevel = double.tryParse(value);
    if (criticalLevel == null || criticalLevel < 0) {
      return "Critical level must be a non-negative number";
    }
    return null;
  }

  String? validateProductPrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Product price cannot be empty";
    }
    final double? price = double.tryParse(value);
    if (price == null || price <= 0) {
      return "Product price must be a non-negative number";
    }
    return null;
  }

  String? validateProductCost(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Product cost cannot be empty";
    }
    final double? cost = double.tryParse(value);
    if (cost == null || cost <= 0) {
      return "Product cost must be a non-negative number";
    }
    return null;
  }

  String? validateProductQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Product quantity cannot be empty";
    }
    final double? quantity = double.tryParse(value);
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
    final double? factor = double.tryParse(value);
    if (factor == null || factor <= 0) {
      return "Factor must be a positive number.";
    }
    return null;
  }

  String? validateSecondaryUnitName({required String? name, required List<String> existingNames}) {
    if (existingNames.contains(name)) {
      return "Alternate unit name already exists.";
    }
    return null;
  }

  String? validateSecondaryUnitFactor({
    required String? name,
    required String? factor,
  }) {
    if (name != null && name.trim().isNotEmpty) {
      if (factor == null || factor.trim().isEmpty) {
        return "Alternate factor cannot be empty.";
      }
      final double? conversionFactor = double.tryParse(factor);
      if (conversionFactor == null || conversionFactor <= 0) {
        return "Alternate factor must be a positive number.";
      }
    }
    return null;
  }

  String? validateDeadStockThreshold(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final double? deadStockThreshold = double.tryParse(value);
    if (deadStockThreshold == null || deadStockThreshold < 0) {
      return "Dead stock threshold must be a non-negative number";
    }
    return null;
  }

  String? validateFastMovingThreshold(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final double? fastMovingThreshold = double.tryParse(value);
    if (fastMovingThreshold == null || fastMovingThreshold < 0) {
      return "Fast moving threshold must be a non-negative number";
    }
    return null;
  }
}
