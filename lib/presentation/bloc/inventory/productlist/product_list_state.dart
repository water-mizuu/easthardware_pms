part of 'product_list_bloc.dart';

class ProductListState {
  final List<Product> allProducts;
  final List<Product> lowStockProducts;
  final List<Product> deadStockProducts;
  final List<Product> fastMovingProducts;
  final DataStatus status;

  ProductListState({
    required this.allProducts,
    required this.lowStockProducts,
    required this.deadStockProducts,
    required this.fastMovingProducts,
    this.status = DataStatus.initial,
  });

  ProductListState Function({
    List<Product> allProducts,
    List<Product> lowStockProducts,
    List<Product> deadStockProducts,
    List<Product> fastMovingProducts,
    DataStatus status,
  }) get copyWith {
    return ({
      Object? allProducts = undefined,
      Object? lowStockProducts = undefined,
      Object? deadStockProducts = undefined,
      Object? fastMovingProducts = undefined,
      Object? status = undefined,
    }) {
      return ProductListState(
        allProducts: allProducts.or(this.allProducts),
        lowStockProducts: lowStockProducts.or(this.lowStockProducts),
        deadStockProducts: deadStockProducts.or(this.deadStockProducts),
        fastMovingProducts: fastMovingProducts.or(this.fastMovingProducts),
        status: status.or(this.status),
      );
    };
  }
}

class ProductsStateInitial extends ProductListState {
  ProductsStateInitial()
      : super(
          allProducts: [],
          lowStockProducts: [],
          deadStockProducts: [],
          fastMovingProducts: [],
        );
}
