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
    final startDate = state.queryData.startDate;
    final endDate = state.queryData.endDate;
    final sortBy = state.queryData.sortBy;

    // Filter invoices by date range (using invoice date)
    final filteredInvoices = invoices.where((invoice) {
      return invoice.invoiceDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          invoice.invoiceDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Map invoices to their payments
    final invoiceSalesData = <(Invoice, List<Payment>)>[];
    for (final invoice in filteredInvoices) {
      final invoicePayments = payments.where((payment) => payment.invoiceId == invoice.id).toList();
      invoiceSalesData.add((invoice, invoicePayments));
    }

    // Apply sorting
    invoiceSalesData.sort(sortBy.compare);

    // Calculate invoice sales summary
    var totalAmountDue = 0.0;
    var totalAmountPaid = 0.0;
    var totalOverpayment = 0.0;
    var paidCount = 0;
    var partialCount = 0;
    var unpaidCount = 0;
    var overpaidCount = 0;

    for (final (invoice, invoicePayments) in invoiceSalesData) {
      final amountDue = invoice.amountDue;
      // Use invoice's amountPaid field if available, otherwise calculate from payments
      final amountPaid = invoice.amountPaid ??
          invoicePayments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      final overpayment = amountPaid > amountDue ? amountPaid - amountDue : 0.0;

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
      totalInvoices: filteredInvoices.length,
      totalAmountDue: totalAmountDue,
      totalAmountPaid: totalAmountPaid,
      totalBalanceDue: totalAmountDue - totalAmountPaid,
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
