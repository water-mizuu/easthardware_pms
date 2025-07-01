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
import 'package:easthardware_pms/presentation/views/dashboard/cards/sales_overview.dart';
import 'package:easthardware_pms/presentation/views/reports/inventory_report/'
    'inventory_query_data.dart';
import 'package:easthardware_pms/utils/duration.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

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

  Future<void> _updateQueryData(Emitter<InventoryReportState> emit) async {
    /// We need to take into account the products that were filtered by the search query.
    ///   Lastly, the products that are included based on the date.

    var result = state.allProducts;
    if (result.isEmpty) {
      final updatedQueryData = state.queryData.copyWith(filteredProducts: []);
      emit(state.copyWith(queryData: updatedQueryData));
      return;
    }

    if (kDebugMode) {
      print(state.queryData.date);
    }

    if (state.queryData.date case final queryDate?) {
      /// We only take the products that were created before or on the query date.
      result = result
          .where((p) => DateTime.parse(p.creationDate).isBefore(queryDate.add(1.days)))
          .toList();

      /// We add back the quantities of the products that were invoiced after the query date.
      for (final invoice in state.allInvoices) {
        if (!invoice.creationDate.isAfter(queryDate)) continue;

        for (final product in state.allInvoiceProducts) {
          if (product.invoiceId != invoice.id) continue;

          final found = result.indexed //
              .where((p) => p.$2.id == product.productId)
              .firstOrNull;

          if (found case (final index, final item)) {
            result[index] = item.copyWith(quantity: item.quantity + product.quantity);
          }
        }
      }

      /// We remove the quantities of the products that were ordered after the query date.
      for (final order in state.allOrders) {
        if (!order.creationDate.isAfter(queryDate)) continue;

        for (final product in state.allOrderProducts) {
          if (product.orderId != order.id) continue;

          final found = result.indexed //
              .where((p) => p.$2.id == product.productId)
              .firstOrNull;

          if (found case (final index, final item)) {
            result[index] = item.copyWith(quantity: item.quantity - product.quantity);
          }
        }
      }

      if (!queryDate.zeroedTime().isAtSameMomentAs(DateTime.now().zeroedTime())) {
        for (var i = 0; i < result.length; ++i) {
          /// We remove the statuses as they are not computable for this report.
          result[i] = result[i].copyWith(
            isBelowReorderPoint: false,
            isDeadStock: false,
            isFastMovingStock: false,
          );
        }
      }
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
