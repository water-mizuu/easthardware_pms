part of 'inventory_display_bloc.dart';

class InventoryDisplayState with EquatableMixin {
  const InventoryDisplayState({
    required this.allProducts,
    this.filteredProducts,
    this.searchQuery = '',
    this.category,
    this.sortBy = InventoryDisplaySortBy.urgency,
  });

  InventoryDisplayState.empty()
      : allProducts = null,
        filteredProducts = null,
        searchQuery = '',
        category = null,
        sortBy = InventoryDisplaySortBy.urgency;

  final WeakReference<List<Product>>? allProducts;
  final List<Product>? filteredProducts;
  final String searchQuery;
  final Category? category;
  final InventoryDisplaySortBy sortBy;

  InventoryDisplayState Function({
    WeakReference<List<Product>>? allProducts,
    List<Product>? filteredProducts,
    String searchQuery,
    Category? category,
    InventoryDisplaySortBy sortBy,
  }) get copyWith {
    return ({
      Object? allProducts = undefined,
      Object? filteredProducts = undefined,
      Object? searchQuery = undefined,
      Object? category = undefined,
      Object sortBy = undefined,
    }) {
      return InventoryDisplayState(
        allProducts: allProducts.or(this.allProducts),
        filteredProducts: filteredProducts.or(this.filteredProducts),
        searchQuery: searchQuery.or(this.searchQuery),
        category: category.or(this.category),
        sortBy: sortBy.or(this.sortBy),
      );
    };
  }

  @override
  List<Object?> get props => [allProducts, filteredProducts, searchQuery, category, sortBy];
}
