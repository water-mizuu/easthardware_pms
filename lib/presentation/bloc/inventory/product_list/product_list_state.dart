part of 'product_list_bloc.dart';

class ProductListState with EquatableMixin {
  const ProductListState({
    required this.allProducts,
    required this.lowStockProducts,
    required this.deadStockProducts,
    required this.fastMovingProducts,
    this.latest,
    this.status = DataStatus.initial,
  });

  const ProductListState.initial()
      : allProducts = const [],
        lowStockProducts = const [],
        deadStockProducts = const [],
        fastMovingProducts = const [],
        status = DataStatus.initial,
        latest = null;

  final List<Product> allProducts;
  final List<Product> lowStockProducts;
  final List<Product> deadStockProducts;
  final List<Product> fastMovingProducts;
  final Product? latest;
  final DataStatus status;

  ProductListState Function({
    List<Product> allProducts,
    List<Product> lowStockProducts,
    List<Product> deadStockProducts,
    List<Product> fastMovingProducts,
    Product? latest,
    DataStatus status,
  }) get copyWith {
    return ({
      Object? allProducts = undefined,
      Object? lowStockProducts = undefined,
      Object? deadStockProducts = undefined,
      Object? fastMovingProducts = undefined,
      Product? latest,
      Object? status = undefined,
    }) {
      return ProductListState(
        allProducts: allProducts.or(this.allProducts),
        lowStockProducts: lowStockProducts.or(this.lowStockProducts),
        deadStockProducts: deadStockProducts.or(this.deadStockProducts),
        fastMovingProducts: fastMovingProducts.or(this.fastMovingProducts),
        latest: latest.or(this.latest),
        status: status.or(this.status),
      );
    };
  }

  @override
  List<Object?> get props => [
        allProducts,
        lowStockProducts,
        deadStockProducts,
        fastMovingProducts,
        status,
      ];
}
