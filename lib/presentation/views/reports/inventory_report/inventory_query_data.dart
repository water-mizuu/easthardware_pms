import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_display/'
    'inventory_display_enum.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/sales_overview.dart';
import 'package:easthardware_pms/utils/undefined.dart';

class InventoryQueryData {
  const InventoryQueryData({
    required this.date,
    required this.filteredProducts,
    required this.searchQuery,
    required this.category,
    required this.sortBy,
  });

  InventoryQueryData.empty()
      : date = DateTime.now().zeroedTime(),
        filteredProducts = const [],
        searchQuery = '',
        category = null,
        sortBy = InventoryDisplaySortBy.urgencyAscending;

  final DateTime? date;
  final List<Product>? filteredProducts;
  final String searchQuery;
  final Category? category;
  final InventoryDisplaySortBy sortBy;

  InventoryQueryData Function({
    DateTime? date,
    List<Product>? filteredProducts,
    String searchQuery,
    Category? category,
    InventoryDisplaySortBy sortBy,
  }) get copyWith {
    return ({
      Object? date = undefined,
      Object? filteredProducts = undefined,
      Object? searchQuery = undefined,
      Object? category = undefined,
      Object? sortBy = undefined,
    }) {
      return InventoryQueryData(
        date: date.or(this.date),
        filteredProducts: filteredProducts.or(this.filteredProducts),
        searchQuery: searchQuery.or(this.searchQuery),
        category: category.or(this.category),
        sortBy: sortBy.or(this.sortBy),
      );
    };
  }
}
