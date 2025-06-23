part of 'inventory_display_bloc.dart';

class InventoryDisplayState with EquatableMixin {
  const InventoryDisplayState({
    required this.allProducts,
    this.filteredProducts,
    this.searchQuery = '',
    this.category,
    this.sortBy = InventoryDisplaySortBy.urgency,
    this.sortAscending = true,
  });

  InventoryDisplayState.empty()
      : allProducts = null,
        filteredProducts = null,
        searchQuery = '',
        category = null,
        sortBy = InventoryDisplaySortBy.urgency,
        sortAscending = true;

  final WeakReference<List<Product>>? allProducts;
  final List<Product>? filteredProducts;
  final String searchQuery;
  final Category? category;
  final InventoryDisplaySortBy sortBy;
  final bool sortAscending;

  InventoryDisplayState Function({
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    String searchQuery,
    Category? category,
    InventoryDisplaySortBy sortBy,
    bool sortAscending,
  }) get copyWith {
    return ({
      Object? allProducts = undefined,
      Object? filteredProducts = undefined,
      Object? searchQuery = undefined,
      Object? category = undefined,
      Object sortBy = undefined,
      Object? sortAscending = undefined,
    }) {
      return InventoryDisplayState(
        allProducts: allProducts == undefined
            ? this.allProducts
            : allProducts == null
                ? null
                : WeakReference(allProducts as List<Product>),
        //
        filteredProducts: filteredProducts.or(this.filteredProducts),
        searchQuery: searchQuery.or(this.searchQuery),
        category: category.or(this.category),
        sortBy: sortBy.or(this.sortBy),
        sortAscending: sortAscending.or(this.sortAscending),
      );
    };
  }

  @override
  List<Object?> get props => [
        allProducts,
        filteredProducts,
        searchQuery,
        category,
        sortBy,
        sortAscending,
      ];
}
