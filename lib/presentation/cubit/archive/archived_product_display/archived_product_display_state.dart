part of 'archived_product_display_cubit.dart';

class ArchivedProductDisplayState extends Equatable {
  const ArchivedProductDisplayState({
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.sortBy = ArchivedProductSortBy.idAscending,
    this.sortAscending = true,
  });

  final List<Product> allProducts;
  final List<Product> filteredProducts;
  final ArchivedProductSortBy sortBy;
  final bool sortAscending;

  ArchivedProductDisplayState copyWith({
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    ArchivedProductSortBy? sortBy,
    bool? sortAscending,
  }) {
    return ArchivedProductDisplayState(
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  @override
  List<Object?> get props => [allProducts, filteredProducts, sortBy, sortAscending];
}
