import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_display/'
    'inventory_display_enum.dart';
import 'package:easthardware_pms/presentation/views/reports/inventory_report/'
    'inventory_query_data.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';

part 'inventory_report_event.dart';
part 'inventory_report_state.dart';

class InventoryReportBloc extends Bloc<InventoryReportEvent, InventoryReportState> {
  InventoryReportBloc(List<Product> allProducts)
      : super(InventoryReportState(
          allProducts: WeakReference(allProducts),
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
    var result = state.allProducts.target;
    if (result == null || result.isEmpty) {
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
      state.queryData.sortBy.compareProducts,
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
