part of 'product_form_bloc.dart';

class ProductFormState extends Equatable {
  // Data Entity attributes

  // Basic Product Information
  final String name;
  final String sku;

  // Form specific attribute to handle creation of new category
  final String categoryName;
  // Category ID that will be generated while submitting the form
  final int? categoryId;

  final String? description;
  final String price;
  final String cost;
  final String quantity;
  final String mainUnit;
  final String criticalLevel;

  // Form specific attribute to handle automated critical level creation
  final bool isCriticalLevelEdited;

  final String deadstockTreshold;
  final String fastmovingTreshold;

  // Product Secondary Units
  final List<FormUnit> secondaryUnits;

  // Product Creation Information, Hidden from Form
  final DateTime creationDate;
  final int? archiveStatus;
  final int? creatorId;

  // Temporary Solution to not use repositories
  final int? productId;

  final FormStatus formStatus;

  ProductFormState({
    this.name = '',
    String? sku,
    this.categoryName = '',
    this.categoryId,
    this.description,
    this.price = '',
    this.cost = '',
    this.quantity = '',
    this.mainUnit = '',
    List<FormUnit>? secondaryUnits,
    this.criticalLevel = '',
    this.isCriticalLevelEdited = false,
    String? deadstockTreshold,
    String? fastmovingTreshold,
    DateTime? creationDate,
    this.creatorId,
    this.productId,
    this.archiveStatus,
    this.formStatus = FormStatus.initial,
  })  : sku = const Uuid().v4().toString(),
        secondaryUnits = secondaryUnits ?? [FormUnit(name: '', factor: '')],
        creationDate = creationDate ?? DateTime.now(),
        deadstockTreshold = deadstockTreshold ?? DEFAULT_DEAD_STOCK_THRESHOLD.toString(),
        fastmovingTreshold = fastmovingTreshold ?? DEFAULT_FAST_MOVING_STOCK_THRESHOLD.toString();

  ProductFormState Function({
    String name,
    String sku,
    String categoryName,
    int? categoryId,
    String? description,
    String price,
    String cost,
    String quantity,
    String mainUnit,
    List<FormUnit> secondaryUnits,
    String criticalLevel,
    bool isCriticalLevelEdited,
    String deadstockTreshold,
    String fastmovingTreshold,
    DateTime creationDate,
    int? archiveStatus,
    int? creatorId,
    FormStatus formStatus,
    int? productId,
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
      Object? isCriticalLevelEdited = undefined,
      Object? deadstockTreshold = undefined,
      Object? fastmovingTreshold = undefined,
      Object? creationDate = undefined,
      Object? archiveStatus = undefined,
      Object? creatorId = undefined,
      Object? formStatus = undefined,
      Object? productId = undefined,
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
        isCriticalLevelEdited: isCriticalLevelEdited.or(this.isCriticalLevelEdited),
        deadstockTreshold: deadstockTreshold.or(this.deadstockTreshold),
        fastmovingTreshold: fastmovingTreshold.or(this.fastmovingTreshold),
        creationDate: creationDate.or(this.creationDate),
        archiveStatus: archiveStatus.or(this.archiveStatus),
        creatorId: creatorId.or(this.creatorId),
        productId: productId.or(this.productId),
        formStatus: formStatus.or(this.formStatus),
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
        isCriticalLevelEdited,
        deadstockTreshold,
        fastmovingTreshold,
        creationDate,
        archiveStatus,
        creatorId,
        formStatus,
        productId,
      ];

  Product mapStateToProduct() {
    return Product(
      sku: sku,
      name: name,
      categoryId: categoryId,
      description: description,
      salePrice: double.parse(price),
      orderCost: double.parse(cost),
      quantity: double.parse(quantity),
      mainUnit: mainUnit,
      criticalLevel: double.parse(criticalLevel),
      deadStockThreshold: double.parse(deadstockTreshold),
      fastMovingStockThreshold: double.parse(deadstockTreshold),
      creationDate: creationDate.toIso8601String(),
      creatorId: creatorId!,
      archiveStatus: archiveStatus!,
    );
  }

  factory ProductFormState.fromProduct(Product product, List<Unit> units) {
    return ProductFormState(
      name: product.name,
      sku: product.sku,
      categoryId: product.categoryId,
      categoryName: product.categoryName!,
      description: product.description,
      price: product.salePrice.toString(),
      cost: product.orderCost.toString(),
      quantity: product.quantity.toString(),
      mainUnit: product.mainUnit,
      criticalLevel: product.criticalLevel.toString(),
      deadstockTreshold: product.deadStockThreshold.toString(),
      fastmovingTreshold: product.fastMovingStockThreshold.toString(),
      secondaryUnits:
          units.isEmpty ? [FormUnit(name: '', factor: '')] : units.map(FormUnit.fromUnit).toList(),
      creationDate: DateTime.parse(product.creationDate),
      creatorId: product.creatorId,
      archiveStatus: product.archiveStatus,
      productId: product.id!,
    );
  }
}

class ProductFormInitial extends ProductFormState {
  ProductFormInitial() : super();
}
