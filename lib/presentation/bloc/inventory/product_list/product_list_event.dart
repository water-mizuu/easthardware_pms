part of 'product_list_bloc.dart';

sealed class ProductListEvent extends Equatable {
  const ProductListEvent();

  @override
  List<Object> get props => [];
}

class LoadAllProductsEvent extends ProductListEvent {
  const LoadAllProductsEvent();
}

class AddProductEvent extends ProductListEvent {
  const AddProductEvent({
    required this.product,
    required this.category,
    required this.units,
  });

  final Product product;
  final List<Unit> units;
  final Category category;

  @override
  List<Object> get props => [product, category, units];
}

class UpdateProductEvent extends ProductListEvent {
  const UpdateProductEvent(
    this.product,
    this.category,
    this.units,
  );

  final Product product;
  final Category category;
  final List<Unit> units;

  @override
  List<Object> get props => [product];
}

class ArchiveProductEvent extends ProductListEvent {
  const ArchiveProductEvent(this.product);
  final Product product;

  @override
  List<Object> get props => [product];
}

class UnarchiveProductEvent extends ProductListEvent {
  const UnarchiveProductEvent(this.product);
  final Product product;

  @override
  List<Object> get props => [product];
}

class DeleteProductEvent extends ProductListEvent {
  const DeleteProductEvent(this.productId);
  final int productId;

  @override
  List<Object> get props => [productId];
}
