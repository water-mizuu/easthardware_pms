import 'dart:async';

import 'package:dart_bloc_concurrency/dart_bloc_concurrency.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/'
    'inventory_display/inventory_display_enum.dart';
import 'package:easthardware_pms/utils/duration.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'inventory_display_event.dart';
part 'inventory_display_state.dart';

class InventoryDisplayBloc extends Bloc<InventoryDisplayEvent, InventoryDisplayState> {
  InventoryDisplayBloc() : super(InventoryDisplayState.empty()) {
    on<InventoryDisplayItemsUpdatedEvent>(_onItemsUpdated);
    on<InventoryDisplaySearchEvent>(_onSearch);
    on<InventoryDisplayCategoryEvent>(_onCategory);
    on<InventoryDisplaySortEvent>(_onSort);
    on<_InventoryDisplayProcessQueryEvent>(_onProcessQuery, transformer: debounce(100.ms));
  }

  Future<void> _onItemsUpdated(
    InventoryDisplayItemsUpdatedEvent event,
    Emitter<InventoryDisplayState> emit,
  ) async {
    final allProducts = event.allProducts.target;
    if (allProducts == null || allProducts.isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        filteredProducts: null,
        allProducts: null,
      ));
      return;
    }

    emit(state.copyWith(allProducts: event.allProducts));
    add(const _InventoryDisplayProcessQueryEvent());
  }

  Future<void> _onSearch(
    InventoryDisplaySearchEvent event,
    Emitter<InventoryDisplayState> emit,
  ) async {
    final allProducts = state.allProducts;
    if (allProducts == null || allProducts.target == null || allProducts.target!.isEmpty) {
      emit(state.copyWith(
        searchQuery: event.searchQuery,
        allProducts: null,
      ));
      return;
    }

    emit(state.copyWith(searchQuery: event.searchQuery));
    add(const _InventoryDisplayProcessQueryEvent());
  }

  FutureOr<void> _onCategory(
    InventoryDisplayCategoryEvent event,
    Emitter<InventoryDisplayState> emit,
  ) {
    emit(state.copyWith(category: event.category));
    add(const _InventoryDisplayProcessQueryEvent());
  }

  FutureOr<void> _onSort(
    InventoryDisplaySortEvent event,
    Emitter<InventoryDisplayState> emit,
  ) {
    // Check if we're selecting the same sort type that's already active
    if (state.sortBy == event.sortBy) {
      // Toggle the sort direction if the same sort type is selected again
      emit(state.copyWith(sortAscending: !state.sortAscending));

      // Determine the appropriate sort type based on the field and direction
      final newSortBy = _getSortTypeBasedOnDirection(event.sortBy, !state.sortAscending);
      emit(state.copyWith(sortBy: newSortBy));
    } else {
      // Default to ascending order for new sort type
      emit(state.copyWith(
        sortBy: event.sortBy,
        sortAscending: true,
      ));
    }

    add(const _InventoryDisplayProcessQueryEvent());
  }

  // Helper method to get the correct sort type based on direction
  InventoryDisplaySortBy _getSortTypeBasedOnDirection(
    InventoryDisplaySortBy currentSort,
    bool ascending,
  ) {
    switch (currentSort) {
      case InventoryDisplaySortBy.nameAscending:
      case InventoryDisplaySortBy.nameDescending:
        return ascending
            ? InventoryDisplaySortBy.nameAscending
            : InventoryDisplaySortBy.nameDescending;

      case InventoryDisplaySortBy.categoryAscending:
      case InventoryDisplaySortBy.categoryDescending:
        return ascending
            ? InventoryDisplaySortBy.categoryAscending
            : InventoryDisplaySortBy.categoryDescending;

      case InventoryDisplaySortBy.stockAscending:
      case InventoryDisplaySortBy.stockDescending:
        return ascending
            ? InventoryDisplaySortBy.stockAscending
            : InventoryDisplaySortBy.stockDescending;

      case InventoryDisplaySortBy.priceAscending:
      case InventoryDisplaySortBy.priceDescending:
        return ascending
            ? InventoryDisplaySortBy.priceAscending
            : InventoryDisplaySortBy.priceDescending;

      case InventoryDisplaySortBy.urgency:
        return InventoryDisplaySortBy.urgency; // This doesn't have a reverse direction
    }
  }

  Future<void> _onProcessQuery(
    _InventoryDisplayProcessQueryEvent event,
    Emitter<InventoryDisplayState> emit,
  ) async {
    emit(state.copyWith(filteredProducts: null));

    var result = state.allProducts?.target;
    if (result == null || result.isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        filteredProducts: null,
      ));
      return;
    }

    if (state.category != null) {
      result = result.where((product) => product.categoryId == state.category!.id).toList();
    }

    result = await Levenshtein.rankItems<Product>(
      result,
      state.searchQuery,
      (product) => {
        product.sku,
        product.name,
        if (product.description case final description?) description,
        if (product.categoryName case final categoryName?) categoryName,
      },
      switch (state.sortBy) {
        InventoryDisplaySortBy.nameAscending => (a, b) => a.name.compareTo(b.name),
        InventoryDisplaySortBy.nameDescending => (a, b) => b.name.compareTo(a.name),
        InventoryDisplaySortBy.categoryAscending => (a, b) =>
            (a.categoryName ?? '').compareTo(b.categoryName ?? ''),
        InventoryDisplaySortBy.categoryDescending => (a, b) =>
            (b.categoryName ?? '').compareTo(a.categoryName ?? ''),
        InventoryDisplaySortBy.stockAscending => (a, b) => a.quantity.compareTo(b.quantity),
        InventoryDisplaySortBy.stockDescending => (a, b) => b.quantity.compareTo(a.quantity),
        InventoryDisplaySortBy.priceAscending => (a, b) => a.salePrice.compareTo(b.salePrice),
        InventoryDisplaySortBy.priceDescending => (a, b) => b.salePrice.compareTo(a.salePrice),
        InventoryDisplaySortBy.urgency => (a, b) {
            late final isAStockGone = a.quantity <= 0;
            late final isBStockGone = b.quantity <= 0;

            late final isAStockLow = a.quantity < a.criticalLevel;
            late final isBStockLow = b.quantity < b.criticalLevel;

            /// If they're both out of stock, sort by name.
            if (isAStockGone && isBStockGone) {
              return a.name.compareTo(b.name); // Both are out of stock
            }

            /// If only left is out of stock, return -1 (left is more urgent).
            else if (isAStockGone) {
              return -1; // A is out of stock, B is not
            }

            /// If only right is out of stock, return 1 (right is more urgent).
            else if (isBStockGone) {
              return 1; // B is out of stock, A is not
            }

            /// If they're both not zero stock, check if they're low stock.
            ///   If both are low stock, sort by name.
            else if (isAStockLow && isBStockLow) {
              return a.name.compareTo(b.name); // Both are low stock
            }

            /// If only one is low stock, sort by urgency.
            else if (isAStockLow) {
              return -1; // A is low stock, B is not
            } else if (isBStockLow) {
              return 1; // B is low stock, A is not
            }

            return a.name.compareTo(b.name); // Both are in stock, sort by name
          },
      },
    );

    // Sort direction is now handled in the _onSort method
    emit(state.copyWith(filteredProducts: result));
  }
}
