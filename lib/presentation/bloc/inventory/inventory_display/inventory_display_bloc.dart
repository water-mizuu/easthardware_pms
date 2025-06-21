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
    emit(state.copyWith(sortBy: event.sortBy));
    add(const _InventoryDisplayProcessQueryEvent());
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

    emit(state.copyWith(filteredProducts: result));
  }
}
