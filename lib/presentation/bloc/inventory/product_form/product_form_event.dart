part of 'product_form_bloc.dart';

sealed class ProductFormEvent extends Equatable {
  const ProductFormEvent();
  @override
  List<Object> get props => [];
}

class NameFieldChangedEvent extends ProductFormEvent {
  const NameFieldChangedEvent(this.name);
  final String name;
}

class SkuFieldChangedEvent extends ProductFormEvent {
  const SkuFieldChangedEvent(this.sku);
  final String sku;
}

class CategoryFieldChangedEvent extends ProductFormEvent {
  const CategoryFieldChangedEvent(this.category);
  final String category;
}

class CategoryIdChangedEvent extends ProductFormEvent {
  const CategoryIdChangedEvent(this.categoryId);
  final int categoryId;
}

class DescriptionChangedEvent extends ProductFormEvent {
  const DescriptionChangedEvent(this.description);
  final String description;
}

class PriceFieldChangedEvent extends ProductFormEvent {
  const PriceFieldChangedEvent(this.price);
  final double price;
}

class CostFieldChangedEvent extends ProductFormEvent {
  const CostFieldChangedEvent(this.cost);
  final double cost;
}

class QuantityFieldChangedEvent extends ProductFormEvent {
  const QuantityFieldChangedEvent(this.quantity);
  final double quantity;
}

class MainUnitFieldChangedEvent extends ProductFormEvent {
  const MainUnitFieldChangedEvent(this.unit);
  final String unit;
}

class SecondaryUnitFieldNameChangedEvent extends ProductFormEvent {
  const SecondaryUnitFieldNameChangedEvent(this.index, {required this.name});
  final String name;
  final int index;
}

class SecondaryUnitFieldFactorChangedEvent extends ProductFormEvent {
  const SecondaryUnitFieldFactorChangedEvent(
    this.index, {
    required this.mainQuantity,
    required this.unitQuantity,
  });

  final String mainQuantity;
  final String unitQuantity;
  final int index;
}

class SecondaryUnitFieldAddedEvent extends ProductFormEvent {}

class SecondaryUnitFieldDeletedEvent extends ProductFormEvent {
  const SecondaryUnitFieldDeletedEvent(this.index);
  final int index;
}

class CriticalLevelFieldChangedEvent extends ProductFormEvent {
  const CriticalLevelFieldChangedEvent(this.criticalLevel);
  final double criticalLevel;
}

class MinReorderDelayFieldChangedEvent extends ProductFormEvent {
  const MinReorderDelayFieldChangedEvent(this.minReorderDelay);
  final int minReorderDelay;
}

class MaxReorderDelayFieldChangedEvent extends ProductFormEvent {
  const MaxReorderDelayFieldChangedEvent(this.maxReorderDelay);
  final int maxReorderDelay;
}

class DeadstockFieldChangedEvent extends ProductFormEvent {
  const DeadstockFieldChangedEvent(this.threshold);
  final double threshold;
}

class FastMovingStockFieldChangedEvent extends ProductFormEvent {
  const FastMovingStockFieldChangedEvent(this.threshold);
  final double threshold;
}

class ProductStatusChangedEvent extends ProductFormEvent {
  const ProductStatusChangedEvent(this.status);
  final int status;
}

class SaveProductRequestEvent extends ProductFormEvent {
  const SaveProductRequestEvent({required this.productId, required this.creatorId});
  final int productId;
  final int creatorId;
}

class UpdateProductRequestEvent extends ProductFormEvent {
  const UpdateProductRequestEvent({required this.productId, required this.creatorId});
  final int productId;
  final int creatorId;
}

class ArchiveProductRequestEvent extends ProductFormEvent {
  const ArchiveProductRequestEvent({required this.productId, required this.creatorId});
  final int productId;
  final int creatorId;
}

class ProductLoadedEvent extends ProductFormEvent {
  const ProductLoadedEvent(this.product, this.secondaryUnits);
  final Product product;
  final List<Unit> secondaryUnits;
}

class FormSubmittedEvent extends ProductFormEvent {}

class FormResetEvent extends ProductFormEvent {}
