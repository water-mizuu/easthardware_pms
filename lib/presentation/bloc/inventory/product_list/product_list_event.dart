part of 'product_list_bloc.dart';

sealed class ProductListEvent extends Equatable {
  const ProductListEvent();

  @override
  List<Object> get props => [];
}

class LoadAllProductsEvent extends ProductListEvent {}

class ReloadAllProductsEvent extends ProductListEvent {}

class AddProductEvent extends ProductListEvent {
  const AddProductEvent(this.product);

  final Product product;

  @override
  List<Object> get props => [product];
}

class UpdateProductEvent extends ProductListEvent {
  const UpdateProductEvent(this.product);

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
