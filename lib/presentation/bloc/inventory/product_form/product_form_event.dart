part of 'product_form_bloc.dart';

sealed class ProductFormEvent extends Equatable {
  const ProductFormEvent();
  @override
  List<Object> get props => [];
}

class NameFieldChangedEvent extends ProductFormEvent {
  final String name;

  const NameFieldChangedEvent(this.name);
}

class SkuFieldChangedEvent extends ProductFormEvent {
  final String sku;
  const SkuFieldChangedEvent(this.sku);
}

class CategoryFieldChangedEvent extends ProductFormEvent {
  final String category;

  const CategoryFieldChangedEvent(this.category);
}

class CategoryIdChangedEvent extends ProductFormEvent {
  final int categoryId;

  const CategoryIdChangedEvent(this.categoryId);
}

class DescriptionFieldChangedEvent extends ProductFormEvent {
  final String description;

  const DescriptionFieldChangedEvent(this.description);
}

class PriceFieldChangedEvent extends ProductFormEvent {
  final String price;

  const PriceFieldChangedEvent(this.price);
}

class CostFieldChangedEvent extends ProductFormEvent {
  final String cost;

  const CostFieldChangedEvent(this.cost);
}

class QuantityFieldChangedEvent extends ProductFormEvent {
  final String quantity;

  const QuantityFieldChangedEvent(this.quantity);
}

class MainUnitFieldChangedEvent extends ProductFormEvent {
  final String unit;

  const MainUnitFieldChangedEvent(this.unit);
}

class SecondaryUnitFieldNameChangedEvent extends ProductFormEvent {
  final String name;
  final int index;
  const SecondaryUnitFieldNameChangedEvent(this.name, this.index);
}

class SecondaryUnitFieldFactorChangedEvent extends ProductFormEvent {
  final String factor;
  final int index;
  const SecondaryUnitFieldFactorChangedEvent(this.factor, this.index);
}

class SecondaryUnitFieldAddedEvent extends ProductFormEvent {}

class SecondaryUnitFieldDeletedEvent extends ProductFormEvent {
  final int index;
  const SecondaryUnitFieldDeletedEvent(this.index);
}

class CriticalLevelFieldChangedEvent extends ProductFormEvent {
  final String criticalLevel;

  const CriticalLevelFieldChangedEvent(this.criticalLevel);
}

class DeadstockFieldChangedEvent extends ProductFormEvent {
  final String threshold;

  const DeadstockFieldChangedEvent(this.threshold);
}

class FastMovingStockFieldChangedEvent extends ProductFormEvent {
  final String threshold;

  const FastMovingStockFieldChangedEvent(this.threshold);
}

class ProductStatusChangedEvent extends ProductFormEvent {
  final int status;

  const ProductStatusChangedEvent(this.status);
}

class FormButtonPressedEvent extends ProductFormEvent {
  final int productId;
  final int creatorId;
  const FormButtonPressedEvent({required this.productId, required this.creatorId});
}

class ProductLoadedEvent extends ProductFormEvent {
  final Product product;
  final List<Unit> secondaryUnits;
  const ProductLoadedEvent(this.product, this.secondaryUnits);
}

class FormSubmittedEvent extends ProductFormEvent {}

class FormResetEvent extends ProductFormEvent {}
