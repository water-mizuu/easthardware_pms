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
import 'package:flutter/foundation.dart' show kDebugMode;
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

  @override
  Future<void> onEvent(InventoryDisplayEvent event) async {
    if (kDebugMode) {
      print('InventoryDisplayBloc: onEvent: $event');
    }
    super.onEvent(event);
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
    if (kDebugMode) {
      print('Search query: ${event.searchQuery}');
      print('All products: ${allProducts?.target?.map((p) => p.toMap()).toList()}');
    }

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
        null => null,
      },
    );

    emit(state.copyWith(filteredProducts: result));
  }
}
