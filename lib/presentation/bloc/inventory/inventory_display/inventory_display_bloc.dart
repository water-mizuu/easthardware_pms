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

    emit(state.copyWith(allProducts: allProducts));
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
            ? InventoryDisplaySortBy.nameDescending
            : InventoryDisplaySortBy.nameAscending;

      case InventoryDisplaySortBy.categoryAscending:
      case InventoryDisplaySortBy.categoryDescending:
        return ascending
            ? InventoryDisplaySortBy.categoryDescending
            : InventoryDisplaySortBy.categoryAscending;

      case InventoryDisplaySortBy.stockAscending:
      case InventoryDisplaySortBy.stockDescending:
        return ascending
            ? InventoryDisplaySortBy.stockDescending
            : InventoryDisplaySortBy.stockAscending;

      case InventoryDisplaySortBy.priceAscending:
      case InventoryDisplaySortBy.priceDescending:
        return ascending
            ? InventoryDisplaySortBy.priceDescending
            : InventoryDisplaySortBy.priceAscending;

      case InventoryDisplaySortBy.urgencyAscending:
      case InventoryDisplaySortBy.urgencyDescending:
        return ascending
            ? InventoryDisplaySortBy.urgencyDescending
            : InventoryDisplaySortBy.urgencyAscending;
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
      state.sortBy.compareProducts,
    );

    // Sort direction is now handled in the _onSort method
    emit(state.copyWith(filteredProducts: result));
  }
}
