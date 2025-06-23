import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/views/reports/sales_report/sales_query_data.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';

part 'sales_report_event.dart';
part 'sales_report_state.dart';

class SalesReportBloc extends Bloc<SalesReportEvent, SalesReportState> {
  SalesReportBloc(
    List<Product> allProducts,
    List<Invoice> allInvoices,
    List<InvoiceProduct> allInvoiceProducts,
    List<Order> allOrders,
    List<OrderProduct> allOrderProducts,
  ) : super(SalesReportState(
          allProducts: WeakReference(allProducts),
          allInvoices: WeakReference(allInvoices),
          allInvoiceProducts: WeakReference(allInvoiceProducts),
          allOrders: WeakReference(allOrders),
          allOrderProducts: WeakReference(allOrderProducts),
          queryData: SalesQueryData.empty(),
        )) {
    on<SalesReportInitializeEvent>(_onInitialize);
    on<SalesReportSetGeneratingEvent>(_onSetGenerating);
    on<SalesReportSetStartDateEvent>(_onSetStartDate);
    on<SalesReportSetEndDateEvent>(_onSetEndDate);
    on<SalesReportSetSortByEvent>(_onSetSortBy);
    on<SalesReportSetOverlayEvent>(_onSetOverlay);
    on<SalesReportRemoveOverlayEvent>(_onRemoveOverlay);
    on<SalesReportUpdateProductsEvent>(_onUpdateProducts);
    on<SalesReportUpdateInvoicesEvent>(_onUpdateInvoices);
    on<SalesReportUpdateInvoiceProductsEvent>(_onUpdateInvoiceProducts);
    on<SalesReportUpdateOrdersEvent>(_onUpdateOrders);
    on<SalesReportUpdateOrderProductsEvent>(_onUpdateOrderProducts);

    // Initialize the query data
    add(const SalesReportInitializeEvent());
  }

  Future<void> _onInitialize(
      SalesReportInitializeEvent event, Emitter<SalesReportState> emit) async {
    final products = state.allProducts.target ?? <Product>[];
    final invoiceProducts = state.allInvoiceProducts.target ?? <InvoiceProduct>[];
    final orderProducts = state.allOrderProducts.target ?? <OrderProduct>[];

    final salesData = _calculateSalesData(products, invoiceProducts, orderProducts);

    emit(state.copyWith(
      queryData: state.queryData.copyWith(
        salesData: salesData,
      ),
    ));
  }

  void _onSetGenerating(SalesReportSetGeneratingEvent event, Emitter<SalesReportState> emit) {
    emit(state.copyWith(isGenerating: event.isGenerating));
  }

  void _onSetStartDate(SalesReportSetStartDateEvent event, Emitter<SalesReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(startDate: event.startDate),
    ));
    _recalculateSalesData(emit);
  }

  void _onSetEndDate(SalesReportSetEndDateEvent event, Emitter<SalesReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(endDate: event.endDate),
    ));
    _recalculateSalesData(emit);
  }

  void _onSetOverlay(SalesReportSetOverlayEvent event, Emitter<SalesReportState> emit) {
    emit(state.copyWith(overlayEntry: event.overlayEntry));
  }

  void _onRemoveOverlay(SalesReportRemoveOverlayEvent event, Emitter<SalesReportState> emit) {
    final overlay = state.overlayEntry;
    overlay?.remove();
    emit(state.copyWith(overlayEntry: null));
  }

  void _onUpdateProducts(SalesReportUpdateProductsEvent event, Emitter<SalesReportState> emit) {
    emit(state.copyWith(allProducts: event.products));
    _recalculateSalesData(emit);
  }

  void _onUpdateInvoiceProducts(
    SalesReportUpdateInvoiceProductsEvent event,
    Emitter<SalesReportState> emit,
  ) {
    emit(state.copyWith(allInvoiceProducts: event.invoiceProducts));
    _recalculateSalesData(emit);
  }

  void _onUpdateOrderProducts(
    SalesReportUpdateOrderProductsEvent event,
    Emitter<SalesReportState> emit,
  ) {
    emit(state.copyWith(allOrderProducts: event.orderProducts));
    _recalculateSalesData(emit);
  }

  Future<void> _onUpdateOrders(
    SalesReportUpdateOrdersEvent event,
    Emitter<SalesReportState> emit,
  ) async {
    emit(state.copyWith(allOrders: event.orders));
    _recalculateSalesData(emit);
  }

  Future<void> _onUpdateInvoices(
    SalesReportUpdateInvoicesEvent event,
    Emitter<SalesReportState> emit,
  ) async {
    emit(state.copyWith(allInvoices: event.invoices));
    _recalculateSalesData(emit);
  }

  Future<void> _onSetSortBy(
    SalesReportSetSortByEvent event,
    Emitter<SalesReportState> emit,
  ) async {
    emit(state.copyWith(queryData: state.queryData.copyWith(sortBy: event.sortBy)));
    _recalculateSalesData(emit);
  }

  void _recalculateSalesData(Emitter<SalesReportState> emit) {
    final products = state.allProducts.target ?? <Product>[];
    final invoiceProducts = state.allInvoiceProducts.target ?? <InvoiceProduct>[];
    final orderProducts = state.allOrderProducts.target ?? <OrderProduct>[];

    final salesData = _calculateSalesData(products, invoiceProducts, orderProducts);

    emit(state.copyWith(
      queryData: state.queryData.copyWith(
        salesData: salesData,
      ),
    ));
  }

  List<(Product, SalesExtras)> _calculateSalesData(
    List<Product> products,
    List<InvoiceProduct> invoiceProducts,
    List<OrderProduct> orderProducts,
  ) {
    final salesData = <(Product, SalesExtras)>[];
    final startDate = state.queryData.startDate;
    final endDate = state.queryData.endDate;

    final invoiceMap = <int, Invoice>{};
    final orderMap = <int, Order>{};

    for (final product in products) {
      // Calculate units sold from invoice products within date range
      var unitsSold = 0.0;

      for (final invoiceProduct in invoiceProducts) {
        final invoice = invoiceMap.putIfAbsent(
          invoiceProduct.invoiceId ?? -1,
          () => state.allInvoices.target!.firstWhere((i) => i.id == invoiceProduct.invoiceId),
        );

        if (invoice.creationDate.isAfter(endDate) || invoice.creationDate.isBefore(startDate)) {
          continue;
        }

        if (invoiceProduct.productId == product.id) {
          unitsSold += invoiceProduct.quantity;
        }
      }

      // Calculate units ordered from order products within date range
      var unitsOrdered = 0.0;
      for (final orderProduct in orderProducts) {
        final order = orderMap.putIfAbsent(
          orderProduct.orderId,
          () => state.allOrders.target!.firstWhere((i) => i.id == orderProduct.orderId),
        );

        if (order.creationDate.isAfter(endDate) || order.creationDate.isBefore(startDate)) {
          continue;
        }

        if (orderProduct.productId == product.id) {
          unitsOrdered += orderProduct.quantity;
        }
      }

      // Only include products that have sales or orders
      if (unitsSold > 0 || unitsOrdered > 0) {
        salesData.add(
          (
            product,
            SalesExtras(
              unitsSold: unitsSold,
              unitsOrdered: unitsOrdered,
            )
          ),
        );
      }
    }

    salesData.sort((a, b) => state.queryData.sortBy.compare(a, b));

    return salesData;
  }
}
