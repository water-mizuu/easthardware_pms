import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_display/'
    'inventory_display_enum.dart';
import 'package:easthardware_pms/presentation/views/reports/inventory_report/'
    'inventory_query_data.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';

part 'inventory_report_event.dart';
part 'inventory_report_state.dart';

class InventoryReportBloc extends Bloc<InventoryReportEvent, InventoryReportState> {
  InventoryReportBloc(
    List<Invoice> allInvoices,
    List<InvoiceProduct> allInvoiceProducts,
    List<Order> allOrders,
    List<OrderProduct> allOrderProducts,
    List<Product> allProducts,
  ) : super(InventoryReportState(
          allInvoices: allInvoices,
          allInvoiceProducts: allInvoiceProducts,
          allOrders: allOrders,
          allOrderProducts: allOrderProducts,
          allProducts: allProducts,
          filteredProducts: allProducts,
          queryData: InventoryQueryData.empty(),
        )) {
    on<InventoryReportInitializeEvent>(_onInitialize);
    on<InventoryReportSetGeneratingEvent>(_onSetGenerating);
    on<InventoryReportSetDateEvent>(_onSetDate);
    on<InventoryReportUpdateInvoicesEvent>(_onUpdateInvoices);
    on<InventoryReportUpdateOrdersEvent>(_onUpdateOrders);
    on<InventoryReportUpdateProductsEvent>(_onUpdateProducts);
    on<InventoryReportSetSortByEvent>(_onSetSortBy);
    on<InventoryReportSetSearchQueryEvent>(_onSetSearchQuery);
    on<InventoryReportSetFilterEvent>(_onSetFilter);
    on<InventoryReportSetCategoryEvent>(_onSetCategory);
    on<InventoryReportSetRowLimitEvent>(_onSetRowLimit);

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

  Future<void> _onSetDate(
    InventoryReportSetDateEvent event,
    Emitter<InventoryReportState> emit,
  ) async {
    emit(state.copyWith(queryData: state.queryData.copyWith(date: event.date)));

    await _updateQueryData(emit);
  }

  Future<void> _onUpdateOrders(
    InventoryReportUpdateOrdersEvent event,
    Emitter<InventoryReportState> emit,
  ) async {
    emit(state.copyWith(allOrders: event.orders.toList()));
    await _updateQueryData(emit);
  }

  Future<void> _onUpdateInvoices(
    InventoryReportUpdateInvoicesEvent event,
    Emitter<InventoryReportState> emit,
  ) async {
    emit(state.copyWith(allInvoices: event.invoices.toList()));
    await _updateQueryData(emit);
  }

  Future<void> _onUpdateProducts(
    InventoryReportUpdateProductsEvent event,
    Emitter<InventoryReportState> emit,
  ) async {
    emit(state.copyWith(allProducts: event.products.toList()));
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

  Future<void> _onSetRowLimit(
    InventoryReportSetRowLimitEvent event,
    Emitter<InventoryReportState> emit,
  ) async {
    final updatedQueryData = state.queryData.copyWith(rowLimit: event.rowLimit);
    emit(state.copyWith(queryData: updatedQueryData));
    await _updateQueryData(emit);
  }

  FutureOr<void> _onSetFilter(
    InventoryReportSetFilterEvent event,
    Emitter<InventoryReportState> emit,
  ) async {
    emit(state.copyWith(queryData: state.queryData.copyWith(filter: event.filter)));

    await _updateQueryData(emit);
  }

  Future<void> _updateQueryData(Emitter<InventoryReportState> emit) async {
    /// First, filter out archived products except for the archived count
    final unarchivedProducts = state.allProducts.where((p) => p.archiveStatus == 0).toList();
    if (unarchivedProducts.isEmpty) {
      emit(state.copyWith(filteredProducts: []));

      return;
    }

    final filtered = state.queryData.call(
      unarchivedProducts,
      allInvoices: state.allInvoices,
      allInvoiceProducts: state.allInvoiceProducts,
      allOrders: state.allOrders,
      allOrderProducts: state.allOrderProducts,
    );

    emit(state.copyWith(filteredProducts: filtered));
  }

  @override
  Future<void> close() {
    state.overlayEntry?.remove();
    return super.close();
  }
}
