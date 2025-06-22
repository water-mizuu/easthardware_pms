part of 'product_form_bloc.dart';

class ProductFormState extends Equatable {
  const ProductFormState({
    this.name = '',
    this.sku = '',
    this.categoryName = '',
    this.categoryId,
    this.description,
    this.price = 0,
    this.cost = 0,
    this.quantity = 0,
    this.mainUnit = '',
    this.secondaryUnits = const [FormUnit.empty()],
    this.criticalLevel = 0,
    this.isCriticalLevelEdited = false,
    this.minReorderDelay = 0,
    this.maxReorderDelay = 0,
    this.deadStockThreshold = DEFAULT_DEAD_STOCK_THRESHOLD,
    this.fastMovingThreshold = DEFAULT_FAST_MOVING_STOCK_THRESHOLD,
    this.creationDate,
    this.creatorId,
    this.productId,
    this.archivedStatus,
    this.formStatus = FormStatus.initial,
    this.errorMessage,
  });

  factory ProductFormState.fromProduct(Product product, List<Unit> units) {
    return ProductFormState(
      productId: product.id!,
      name: product.name,
      sku: product.sku,
      categoryId: product.categoryId,
      categoryName: product.categoryName!,
      description: product.description,
      price: product.salePrice,
      cost: product.orderCost,
      quantity: product.quantity,
      mainUnit: product.mainUnit,
      criticalLevel: product.criticalLevel,
      minReorderDelay: product.minReorderDelay,
      maxReorderDelay: product.maxReorderDelay,
      deadStockThreshold: product.deadStockThreshold,
      fastMovingThreshold: product.fastMovingStockThreshold,
      secondaryUnits: units.isEmpty //
          ? [const FormUnit.empty()]
          : units.map(FormUnit.fromUnit).toList(),
      creationDate: DateTime.parse(product.creationDate),
      creatorId: product.creatorId,
      archivedStatus: product.archiveStatus,
      errorMessage: null,
    );
  }
  // Data Entity attributes

  // Basic Product Information
  final String name;
  final String sku;

  // Form specific attribute to handle creation of new category
  final String categoryName;
  // Category ID that will be generated while submitting the form
  final int? categoryId;

  final String? description;
  final double price;
  final double cost;
  final double quantity;
  final String mainUnit;
  final double criticalLevel;
  // Reorder Delay in days
  final int minReorderDelay;
  final int maxReorderDelay;

  // Form specific attribute to handle automated critical level creation
  final bool isCriticalLevelEdited;

  final double deadStockThreshold;
  final double fastMovingThreshold;

  // Product Secondary Units
  final List<FormUnit> secondaryUnits;

  // Product Creation Information, Hidden from Form
  final DateTime? creationDate;
  final int? archivedStatus;
  final int? creatorId;

  // Temporary Solution to not use repositories
  final int? productId;

  final FormStatus formStatus;
  final String? errorMessage;

  ProductFormState Function({
    String name,
    String sku,
    String categoryName,
    int? categoryId,
    String? description,
    double price,
    double cost,
    double quantity,
    String mainUnit,
    List<FormUnit> secondaryUnits,
    double criticalLevel,
    int minReorderDelay,
    int maxReorderDelay,
    bool isCriticalLevelEdited,
    double deadStockThreshold,
    double fastMovingThreshold,
    DateTime creationDate,
    int? archivedStatus,
    int? creatorId,
    FormStatus formStatus,
    int? productId,
    String? errorMessage,
  }) get copyWith {
    return ({
      Object? name = undefined,
      Object? sku = undefined,
      Object? categoryName = undefined,
      Object? categoryId = undefined,
      Object? description = undefined,
      Object? price = undefined,
      Object? cost = undefined,
      Object? quantity = undefined,
      Object? mainUnit = undefined,
      Object? secondaryUnits = undefined,
      Object? criticalLevel = undefined,
      Object? minReorderDelay = undefined,
      Object? maxReorderDelay = undefined,
      Object? isCriticalLevelEdited = undefined,
      Object? deadStockThreshold = undefined,
      Object? fastMovingThreshold = undefined,
      Object? creationDate = undefined,
      Object? archivedStatus = undefined,
      Object? creatorId = undefined,
      Object? formStatus = undefined,
      Object? productId = undefined,
      Object? errorMessage = undefined,
    }) {
      return ProductFormState(
        name: name.or(this.name),
        sku: sku.or(this.sku),
        categoryName: categoryName.or(this.categoryName),
        categoryId: categoryId.or(this.categoryId),
        description: description.or(this.description),
        price: price.or(this.price),
        cost: cost.or(this.cost),
        quantity: quantity.or(this.quantity),
        mainUnit: mainUnit.or(this.mainUnit),
        secondaryUnits: secondaryUnits.or(this.secondaryUnits),
        criticalLevel: criticalLevel.or(this.criticalLevel),
        minReorderDelay: minReorderDelay.or(this.minReorderDelay),
        maxReorderDelay: maxReorderDelay.or(this.maxReorderDelay),
        isCriticalLevelEdited: isCriticalLevelEdited.or(this.isCriticalLevelEdited),
        deadStockThreshold: deadStockThreshold.or(this.deadStockThreshold),
        fastMovingThreshold: fastMovingThreshold.or(this.fastMovingThreshold),
        creationDate: creationDate.or(this.creationDate),
        archivedStatus: archivedStatus.or(this.archivedStatus),
        creatorId: creatorId.or(this.creatorId),
        productId: productId.or(this.productId),
        formStatus: formStatus.or(this.formStatus),
        errorMessage: errorMessage.or(this.errorMessage),
      );
    };
  }

  @override
  List<Object?> get props => [
        name,
        sku,
        categoryName,
        categoryId,
        description,
        price,
        cost,
        quantity,
        mainUnit,
        secondaryUnits,
        criticalLevel,
        minReorderDelay,
        maxReorderDelay,
        isCriticalLevelEdited,
        deadStockThreshold,
        fastMovingThreshold,
        creationDate,
        archivedStatus,
        creatorId,
        formStatus,
        productId,
        errorMessage,
      ];

  Product toProduct() {
    return Product(
      sku: sku,
      name: name,
      categoryId: categoryId,
      description: description,
      salePrice: price,
      orderCost: cost,
      quantity: quantity,
      mainUnit: mainUnit,
      criticalLevel: criticalLevel,
      deadStockThreshold: deadStockThreshold,
      fastMovingStockThreshold: fastMovingThreshold,
      creationDate: creationDate!.toIso8601String(),
      creatorId: creatorId!,
      archiveStatus: archivedStatus!,
      minReorderDelay: minReorderDelay,
      maxReorderDelay: maxReorderDelay,
    );
  }
}

class ProductFormInitial extends ProductFormState {
  const ProductFormInitial() : super();
}
