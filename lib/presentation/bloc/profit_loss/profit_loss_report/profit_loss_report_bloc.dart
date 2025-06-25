import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/views/reports/profit_loss_report/profit_loss_query_data.dart';
import 'package:easthardware_pms/utils/num_iterable_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';

part 'profit_loss_report_event.dart';
part 'profit_loss_report_state.dart';

class ProfitLossReportBloc extends Bloc<ProfitLossReportEvent, ProfitLossReportState> {
  ProfitLossReportBloc(
    List<Product> products,
    List<Invoice> invoices,
    List<InvoiceProduct> invoiceProducts,
    List<Order> orders,
    List<OrderProduct> orderProducts,
  ) : super(ProfitLossReportState(
          products: products,
          invoices: invoices,
          invoiceProducts: invoiceProducts,
          orders: orders,
          orderProducts: orderProducts,
          queryData: ProfitLossQueryData.empty(),
        )) {
    on<ProfitLossReportInitializeEvent>(_onInitialize);
    on<ProfitLossReportSetGeneratingEvent>(_onSetGenerating);
    on<ProfitLossReportSetStartDateEvent>(_onSetStartDate);
    on<ProfitLossReportSetEndDateEvent>(_onSetEndDate);
    on<ProfitLossReportSetGroupByEvent>(_onSetGroupBy);
    on<ProfitLossReportSetSortByEvent>(_onSetSortBy);
    on<ProfitLossReportSetOverlayEvent>(_onSetOverlay);
    on<ProfitLossReportRemoveOverlayEvent>(_onRemoveOverlay);

    // Events to update data sources
    on<ProfitLossReportUpdateProductsEvent>(_onUpdateProducts);
    on<ProfitLossReportUpdateInvoicesEvent>(_onUpdateInvoices);
    on<ProfitLossReportUpdateInvoiceProductsEvent>(_onUpdateInvoiceProducts);
    on<ProfitLossReportUpdateOrdersEvent>(_onUpdateOrders);
    on<ProfitLossReportUpdateOrderProductsEvent>(_onUpdateOrderProducts);

    // Initialize the query data
    add(const ProfitLossReportInitializeEvent());
  }

  Future<void> _onInitialize(
    ProfitLossReportInitializeEvent event,
    Emitter<ProfitLossReportState> emit,
  ) async {
    _recalculateProfitLossData(emit);
  }

  void _onSetGenerating(
    ProfitLossReportSetGeneratingEvent event,
    Emitter<ProfitLossReportState> emit,
  ) {
    emit(state.copyWith(isGenerating: event.isGenerating));
  }

  void _onSetStartDate(
    ProfitLossReportSetStartDateEvent event,
    Emitter<ProfitLossReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(startDate: event.startDate),
    ));
    _recalculateProfitLossData(emit);
  }

  void _onSetEndDate(
    ProfitLossReportSetEndDateEvent event,
    Emitter<ProfitLossReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(endDate: event.endDate),
    ));
    _recalculateProfitLossData(emit);
  }

  void _onSetGroupBy(
    ProfitLossReportSetGroupByEvent event,
    Emitter<ProfitLossReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(groupBy: event.groupBy),
    ));
    _recalculateProfitLossData(emit);
  }

  void _onSetSortBy(
    ProfitLossReportSetSortByEvent event,
    Emitter<ProfitLossReportState> emit,
  ) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(sortBy: event.sortBy),
    ));
    _recalculateProfitLossData(emit);
  }

  void _onSetOverlay(
    ProfitLossReportSetOverlayEvent event,
    Emitter<ProfitLossReportState> emit,
  ) {
    emit(state.copyWith(overlayEntry: event.overlayEntry));
  }

  void _onRemoveOverlay(
    ProfitLossReportRemoveOverlayEvent event,
    Emitter<ProfitLossReportState> emit,
  ) {
    final overlay = state.overlayEntry;
    overlay?.remove();
    emit(state.copyWith(overlayEntry: null));
  }

  void _onUpdateProducts(
    ProfitLossReportUpdateProductsEvent event,
    Emitter<ProfitLossReportState> emit,
  ) {
    emit(state.copyWith(products: event.products));
    _recalculateProfitLossData(emit);
  }

  void _onUpdateInvoices(
    ProfitLossReportUpdateInvoicesEvent event,
    Emitter<ProfitLossReportState> emit,
  ) {
    emit(state.copyWith(invoices: event.invoices));
    _recalculateProfitLossData(emit);
  }

  void _onUpdateInvoiceProducts(
    ProfitLossReportUpdateInvoiceProductsEvent event,
    Emitter<ProfitLossReportState> emit,
  ) {
    emit(state.copyWith(invoiceProducts: event.invoiceProducts));
    _recalculateProfitLossData(emit);
  }

  void _onUpdateOrders(
    ProfitLossReportUpdateOrdersEvent event,
    Emitter<ProfitLossReportState> emit,
  ) {
    emit(state.copyWith(orders: event.orders));
    _recalculateProfitLossData(emit);
  }

  void _onUpdateOrderProducts(
    ProfitLossReportUpdateOrderProductsEvent event,
    Emitter<ProfitLossReportState> emit,
  ) {
    emit(state.copyWith(orderProducts: event.orderProducts));
    _recalculateProfitLossData(emit);
  }

  void _recalculateProfitLossData(Emitter<ProfitLossReportState> emit) {
    final invoices = state.invoices;
    final orders = state.orders;

    final startDate = state.queryData.startDate;
    final endDate = state.queryData.endDate.add(const Duration(days: 1)); // Include end date
    final groupBy = state.queryData.groupBy;
    final sortBy = state.queryData.sortBy;

    // Filter invoices and orders by date range
    final filteredInvoices = invoices.where((invoice) {
      return invoice.creationDate.isAfter(startDate) && invoice.creationDate.isBefore(endDate);
    }).toList();

    final filteredOrders = orders.where((order) {
      return order.orderDate.isAfter(startDate) && order.orderDate.isBefore(endDate);
    }).toList();

    // Group the data by the selected grouping
    final groupedData = <DateTime, ProfitLossEntry>{};

    // Function to get normalized date based on grouping
    DateTime getNormalizedDate(DateTime date) {
      switch (groupBy) {
        case ProfitLossGroupBy.day:
          return DateTime(date.year, date.month, date.day);
        case ProfitLossGroupBy.week:
          // Find the first day of the week (Monday)
          final weekDay = date.weekday;
          final daysToSubtract = weekDay - 1;
          return DateTime(date.year, date.month, date.day - daysToSubtract);
        case ProfitLossGroupBy.month:
          return DateTime(date.year, date.month);
        case ProfitLossGroupBy.quarter:
          final quarter = ((date.month - 1) / 3).floor();
          return DateTime(date.year, quarter * 3 + 1);
        case ProfitLossGroupBy.year:
          return DateTime(date.year);
      }
    }

    // Process invoices to calculate revenue
    for (final invoice in filteredInvoices) {
      final date = getNormalizedDate(invoice.creationDate);
      final invoiceProducts =
          state.invoiceProducts.where((ip) => ip.invoiceId == invoice.id).toList();

      var revenue = 0.0;
      for (final invoiceProduct in invoiceProducts) {
        revenue += invoiceProduct.rate * invoiceProduct.quantity;
      }

      if (groupedData.containsKey(date)) {
        final entry = groupedData[date]!;
        groupedData[date] = entry.copyWith(
          revenue: entry.revenue + revenue,
        );
      } else {
        groupedData[date] = ProfitLossEntry(
          date: date,
          revenue: revenue,
          expenses: 0,
          profit: 0, // Will calculate after expenses
          profitMargin: 0, // Will calculate after profit
        );
      }
    }

    // Process orders to calculate expenses
    for (final order in filteredOrders) {
      final date = getNormalizedDate(order.orderDate);

      // For general expense orders, use the amount due
      final expense = order.amountDue;

      if (groupedData.containsKey(date)) {
        final entry = groupedData[date]!;
        groupedData[date] = entry.copyWith(
          expenses: entry.expenses + expense,
        );
      } else {
        groupedData[date] = ProfitLossEntry(
          date: date,
          revenue: 0,
          expenses: expense,
          profit: 0, // Will calculate after expenses
          profitMargin: 0, // Will calculate after profit
        );
      }
    }

    // Calculate profit and profit margin for each entry
    final profitLossData = groupedData.entries.map((entry) {
      final date = entry.key;
      final data = entry.value;
      final profit = data.revenue - data.expenses;
      final profitMargin = data.revenue > 0 ? (profit / data.revenue) * 100 : 0.0;

      return ProfitLossEntry(
        date: date,
        revenue: data.revenue,
        expenses: data.expenses,
        profit: profit,
        profitMargin: profitMargin,
      );
    }).toList();

    // Sort the profit loss data
    profitLossData.sort(sortBy.compare);

    // Calculate summary
    final totalRevenue = profitLossData.map((e) => e.revenue).sum();
    final totalExpenses = profitLossData.map((e) => e.expenses).sum();
    final totalProfit = totalRevenue - totalExpenses;
    final averageProfitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;

    final summary = ProfitLossSummary(
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      totalProfit: totalProfit,
      averageProfitMargin: averageProfitMargin,
      periodStart: startDate,
      periodEnd: endDate.subtract(const Duration(days: 1)), // Adjust back to actual end date
    );

    emit(state.copyWith(
      queryData: state.queryData.copyWith(
        profitLossData: profitLossData,
        summary: summary,
      ),
    ));
  }
}
