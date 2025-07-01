part of 'invoice_sales_report_bloc.dart';

abstract class InvoiceSalesReportEvent extends Equatable {
  const InvoiceSalesReportEvent();

  @override
  List<Object?> get props => [];
}

class InvoiceSalesReportInitializeEvent extends InvoiceSalesReportEvent {
  const InvoiceSalesReportInitializeEvent();
}

class InvoiceSalesReportSetGeneratingEvent extends InvoiceSalesReportEvent {
  const InvoiceSalesReportSetGeneratingEvent(this.isGenerating);

  final bool isGenerating;

  @override
  List<Object?> get props => [isGenerating];
}

class InvoiceSalesReportSetStartDateEvent extends InvoiceSalesReportEvent {
  const InvoiceSalesReportSetStartDateEvent(this.startDate);

  final DateTime startDate;

  @override
  List<Object?> get props => [startDate];
}

class InvoiceSalesReportSetEndDateEvent extends InvoiceSalesReportEvent {
  const InvoiceSalesReportSetEndDateEvent(this.endDate);

  final DateTime endDate;

  @override
  List<Object?> get props => [endDate];
}

class InvoiceSalesReportSetSortByEvent extends InvoiceSalesReportEvent {
  const InvoiceSalesReportSetSortByEvent(this.sortBy);

  final InvoiceSalesReportSortBy sortBy;

  @override
  List<Object?> get props => [sortBy];
}

class InvoiceSalesReportSetRowLimitEvent extends InvoiceSalesReportEvent {
  const InvoiceSalesReportSetRowLimitEvent(this.rowLimit);

  final int? rowLimit;

  @override
  List<Object?> get props => [rowLimit];
}

class InvoiceSalesReportSetOverlayEvent extends InvoiceSalesReportEvent {
  const InvoiceSalesReportSetOverlayEvent(this.overlayEntry);

  final OverlayEntry? overlayEntry;

  @override
  List<Object?> get props => [overlayEntry];
}

class InvoiceSalesReportRemoveOverlayEvent extends InvoiceSalesReportEvent {
  const InvoiceSalesReportRemoveOverlayEvent();
}

class InvoiceSalesReportUpdateInvoicesEvent extends InvoiceSalesReportEvent {
  const InvoiceSalesReportUpdateInvoicesEvent(this.invoices);

  final List<Invoice> invoices;

  @override
  List<Object?> get props => [invoices];
}

class InvoiceSalesReportUpdatePaymentsEvent extends InvoiceSalesReportEvent {
  const InvoiceSalesReportUpdatePaymentsEvent(this.payments);

  final List<Payment> payments;

  @override
  List<Object?> get props => [payments];
}
