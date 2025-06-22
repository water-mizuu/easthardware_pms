import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_display/inventory_display_enum.dart';
import 'package:easthardware_pms/presentation/views/reports/inventory_report/inventory_query_data.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';

part 'inventory_report_event.dart';
part 'inventory_report_state.dart';

class InventoryReportBloc extends Bloc<InventoryReportEvent, InventoryReportState> {
  InventoryReportBloc(List<Product> allProducts)
      : super(InventoryReportState(
          allProducts: [...allProducts],
          queryData: InventoryQueryData.empty(),
        )) {
    on<InventoryReportInitializeEvent>(_onInitialize);
    on<InventoryReportSetGeneratingEvent>(_onSetGenerating);
    on<InventoryReportSetDateEvent>(_onSetDate);
    on<InventoryReportSetOverlayEvent>(_onSetOverlay);
    on<InventoryReportRemoveOverlayEvent>(_onRemoveOverlay);
    on<InventoryReportUpdateProductsEvent>(_onUpdateProducts);
    on<InventoryReportSetSortByEvent>(_onSetSortBy);
    on<InventoryReportSetSearchQueryEvent>(_onSetSearchQuery);
    on<InventoryReportSetCategoryEvent>(_onSetCategory);

    // Initialize the query data
    add(const InventoryReportInitializeEvent());
  }

  Future<void> _onInitialize(
    InventoryReportInitializeEvent event,
    Emitter<InventoryReportState> emit,
  ) async {
    await _updateQueryData(emit);
  }

  void _onSetGenerating(
    InventoryReportSetGeneratingEvent event,
    Emitter<InventoryReportState> emit,
  ) {
    emit(state.copyWith(isGenerating: event.isGenerating));
  }

  void _onSetDate(
    InventoryReportSetDateEvent event,
    Emitter<InventoryReportState> emit,
  ) {
    emit(state.copyWith(selectedDate: event.date));
  }

  void _onSetOverlay(
    InventoryReportSetOverlayEvent event,
    Emitter<InventoryReportState> emit,
  ) {
    emit(state.copyWith(overlayEntry: event.overlayEntry));
  }

  void _onRemoveOverlay(
    InventoryReportRemoveOverlayEvent event,
    Emitter<InventoryReportState> emit,
  ) {
    state.overlayEntry?.remove();
    emit(state.copyWith(overlayEntry: null));
  }

  Future<void> _onUpdateProducts(
    InventoryReportUpdateProductsEvent event,
    Emitter<InventoryReportState> emit,
  ) async {
    emit(state.copyWith(allProducts: [...event.products]));
    await _updateQueryData(emit);
  }

  Future<void> _onSetSortBy(
    InventoryReportSetSortByEvent event,
    Emitter<InventoryReportState> emit,
  ) async {
    final updatedQueryData = state.queryData.copyWith(sortBy: event.sortBy);
    emit(state.copyWith(queryData: updatedQueryData));
    await _updateQueryData(emit);
  }

  Future<void> _onSetSearchQuery(
    InventoryReportSetSearchQueryEvent event,
    Emitter<InventoryReportState> emit,
  ) async {
    final updatedQueryData = state.queryData.copyWith(searchQuery: event.searchQuery);
    emit(state.copyWith(queryData: updatedQueryData));
    await _updateQueryData(emit);
  }

  Future<void> _onSetCategory(
    InventoryReportSetCategoryEvent event,
    Emitter<InventoryReportState> emit,
  ) async {
    final updatedQueryData = state.queryData.copyWith(category: event.category);
    emit(state.copyWith(queryData: updatedQueryData));
    await _updateQueryData(emit);
  }

  Future<void> _updateQueryData(Emitter<InventoryReportState> emit) async {
    var result = state.allProducts;
    if (result.isEmpty) {
      final updatedQueryData = state.queryData.copyWith(filteredProducts: []);
      emit(state.copyWith(queryData: updatedQueryData));
      return;
    }

    if (state.queryData.category != null) {
      result = result.where((p) => p.categoryId == state.queryData.category!.id).toList();
    }

    result = await Levenshtein.rankItems<Product>(
      result,
      state.queryData.searchQuery,
      (product) => {
        product.sku,
        product.name,
        if (product.description case final description?) description,
        if (product.categoryName case final categoryName?) categoryName,
      },
      switch (state.queryData.sortBy) {
        InventoryDisplaySortBy.nameAscending => (a, b) => a.name.compareTo(b.name),
        InventoryDisplaySortBy.nameDescending => (a, b) => b.name.compareTo(a.name),
        InventoryDisplaySortBy.stockAscending => (a, b) => a.quantity.compareTo(b.quantity),
        InventoryDisplaySortBy.stockDescending => (a, b) => b.quantity.compareTo(a.quantity),
        InventoryDisplaySortBy.priceAscending => (a, b) => a.salePrice.compareTo(b.salePrice),
        InventoryDisplaySortBy.priceDescending => (a, b) => b.salePrice.compareTo(a.salePrice),
        InventoryDisplaySortBy.urgency => (a, b) {
            late final isArchivedA = a.archiveStatus == 1;
            late final isArchivedB = b.archiveStatus == 1;

            late final isAStockGone = a.quantity <= 0;
            late final isBStockGone = b.quantity <= 0;

            late final isAStockLow = a.isBelowCriticalLevel == true;
            late final isBStockLow = b.isBelowCriticalLevel == true;

            if (isArchivedA && !isArchivedB) {
              return 1; // A is archived, B is not
            } else if (!isArchivedA && isArchivedB) {
              return -1; // B is archived, A is not
            }

            /// If only left is out of stock, return -1 (left is more urgent).
            if (isAStockGone && !isBStockGone) {
              return -1; // A is out of stock, B is not
            }

            /// If only right is out of stock, return 1 (right is more urgent).
            else if (isBStockGone && !isAStockGone) {
              return 1; // B is out of stock, A is not
            }

            /// If only one is low stock, sort by urgency.
            else if (isAStockLow && !isBStockLow) {
              return -1; // A is low stock, B is not
            } else if (!isAStockLow && isBStockLow) {
              return 1; // B is low stock, A is not
            }

            return a.name.compareTo(b.name); // Both are in stock, sort by name
          },
      },
    );

    final updatedQueryData = state.queryData.copyWith(filteredProducts: result);
    emit(state.copyWith(queryData: updatedQueryData));
  }

  @override
  Future<void> close() {
    state.overlayEntry?.remove();
    return super.close();
  }
}
