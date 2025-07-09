import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/payment.dart';
import 'package:easthardware_pms/presentation/views/reports/sales_report/invoice_sales_query_data.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';

part 'invoice_sales_report_event.dart';
part 'invoice_sales_report_state.dart';

class InvoiceSalesReportBloc extends Bloc<InvoiceSalesReportEvent, InvoiceSalesReportState> {
  InvoiceSalesReportBloc(
    List<Invoice> allInvoices,
    List<Payment> allPayments,
  ) : super(InvoiceSalesReportState(
          allInvoices: allInvoices,
          allPayments: allPayments,
          queryData: InvoiceSalesQueryData.empty(),
        )) {
    on<InvoiceSalesReportInitializeEvent>(_onInitialize);
    on<InvoiceSalesReportSetGeneratingEvent>(_onSetGenerating);
    on<InvoiceSalesReportSetStartDateEvent>(_onSetStartDate);
    on<InvoiceSalesReportSetEndDateEvent>(_onSetEndDate);
    on<InvoiceSalesReportSetSortByEvent>(_onSetSortBy);
    on<InvoiceSalesReportSetRowLimitEvent>(_onSetRowLimit);
    on<InvoiceSalesReportSetOverlayEvent>(_onSetOverlay);
    on<InvoiceSalesReportRemoveOverlayEvent>(_onRemoveOverlay);
    on<InvoiceSalesReportUpdateInvoicesEvent>(_onUpdateInvoices);
    on<InvoiceSalesReportUpdatePaymentsEvent>(_onUpdatePayments);
    on<InvoiceSalesReportSetSearchQueryEvent>(_onSetSearchQuery);
    on<InvoiceSalesReportSetStatusFilterEvent>(_onSetStatusFilter);
    on<InvoiceSalesReportSetCustomerEvent>(_onSetCustomer);

    // Initialize the query data
    add(const InvoiceSalesReportInitializeEvent());
  }

  Future<void> _onInitialize(
    InvoiceSalesReportInitializeEvent event,
    Emitter<InvoiceSalesReportState> emit,
  ) async {
    _recalculateInvoiceSalesData(emit);
  }

  void _onSetGenerating(
      InvoiceSalesReportSetGeneratingEvent event, Emitter<InvoiceSalesReportState> emit) {
    emit(state.copyWith(isGenerating: event.isGenerating));
  }

  void _onSetStartDate(
      InvoiceSalesReportSetStartDateEvent event, Emitter<InvoiceSalesReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(startDate: event.startDate),
    ));
    _recalculateInvoiceSalesData(emit);
  }

  void _onSetEndDate(
      InvoiceSalesReportSetEndDateEvent event, Emitter<InvoiceSalesReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(endDate: event.endDate),
    ));
    _recalculateInvoiceSalesData(emit);
  }

  void _onSetSortBy(InvoiceSalesReportSetSortByEvent event, Emitter<InvoiceSalesReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(sortBy: event.sortBy),
    ));
    _recalculateInvoiceSalesData(emit);
  }

  FutureOr<void> _onSetRowLimit(
      InvoiceSalesReportSetRowLimitEvent event, Emitter<InvoiceSalesReportState> emit) {
    emit(state.copyWith(queryData: state.queryData.copyWith(rowLimit: event.rowLimit)));
    _recalculateInvoiceSalesData(emit);
  }

  void _onSetSearchQuery(
      InvoiceSalesReportSetSearchQueryEvent event, Emitter<InvoiceSalesReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(searchQuery: event.searchQuery),
    ));
    _recalculateInvoiceSalesData(emit);
  }

  void _onSetStatusFilter(
      InvoiceSalesReportSetStatusFilterEvent event, Emitter<InvoiceSalesReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(statusFilter: event.statusFilter),
    ));
    _recalculateInvoiceSalesData(emit);
  }

  void _onSetCustomer(
      InvoiceSalesReportSetCustomerEvent event, Emitter<InvoiceSalesReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(selectedCustomer: event.customer),
    ));
    _recalculateInvoiceSalesData(emit);
  }

  void _onSetOverlay(
      InvoiceSalesReportSetOverlayEvent event, Emitter<InvoiceSalesReportState> emit) {
    emit(state.copyWith(overlayEntry: event.overlayEntry));
  }

  void _onRemoveOverlay(
      InvoiceSalesReportRemoveOverlayEvent event, Emitter<InvoiceSalesReportState> emit) {
    final overlay = state.overlayEntry;
    overlay?.remove();
    emit(state.copyWith(overlayEntry: null));
  }

  void _onUpdateInvoices(
      InvoiceSalesReportUpdateInvoicesEvent event, Emitter<InvoiceSalesReportState> emit) {
    emit(state.copyWith(allInvoices: event.invoices));
    _recalculateInvoiceSalesData(emit);
  }

  void _onUpdatePayments(
      InvoiceSalesReportUpdatePaymentsEvent event, Emitter<InvoiceSalesReportState> emit) {
    emit(state.copyWith(allPayments: event.payments));
    _recalculateInvoiceSalesData(emit);
  }

  void _recalculateInvoiceSalesData(Emitter<InvoiceSalesReportState> emit) {
    final invoices = state.allInvoices;
    final payments = state.allPayments;

    // Use the call method of queryData to filter and sort the data
    final invoiceSalesData = state.queryData.call(invoices, payments);

    // Calculate invoice sales summary
    var totalAmountDue = 0.0;
    var totalAmountPaid = 0.0;
    var totalOverpayment = 0.0;
    var paidCount = 0;
    var partialCount = 0;
    var unpaidCount = 0;
    var overpaidCount = 0;

    for (final data in invoiceSalesData) {
      final amountDue = data.amountDue;
      final amountPaid = data.totalPaid;
      final overpayment = data.overpayment;

      totalAmountDue += amountDue;
      totalAmountPaid += amountPaid;
      totalOverpayment += overpayment;

      if (amountPaid > amountDue) {
        overpaidCount++;
      } else if (amountPaid >= amountDue) {
        paidCount++;
      } else if (amountPaid > 0) {
        partialCount++;
      } else {
        unpaidCount++;
      }
    }

    final invoiceSalesSummary = InvoiceSalesExtras(
      totalInvoices: invoiceSalesData.length,
      totalAmountDue: totalAmountDue,
      totalAmountPaid: totalAmountPaid,
      totalBalanceDue: totalAmountDue - totalAmountPaid + totalOverpayment,
      totalOverpayment: totalOverpayment,
      paidCount: paidCount,
      partialCount: partialCount,
      unpaidCount: unpaidCount,
      overpaidCount: overpaidCount,
    );

    emit(state.copyWith(
      queryData: state.queryData.copyWith(
        invoiceSalesData: invoiceSalesData,
        invoiceSalesSummary: invoiceSalesSummary,
      ),
    ));
  }
}
