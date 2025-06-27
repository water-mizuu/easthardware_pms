part of 'profit_loss_report_bloc.dart';

abstract class ProfitLossReportEvent extends Equatable {
  const ProfitLossReportEvent();

  @override
  List<Object?> get props => [];
}

class ProfitLossReportInitializeEvent extends ProfitLossReportEvent {
  const ProfitLossReportInitializeEvent();
}

class ProfitLossReportSetGeneratingEvent extends ProfitLossReportEvent {
  const ProfitLossReportSetGeneratingEvent(this.isGenerating);
  final bool isGenerating;

  @override
  List<Object?> get props => [isGenerating];
}

class ProfitLossReportSetStartDateEvent extends ProfitLossReportEvent {
  const ProfitLossReportSetStartDateEvent(this.startDate);
  final DateTime startDate;

  @override
  List<Object?> get props => [startDate];
}

class ProfitLossReportSetEndDateEvent extends ProfitLossReportEvent {
  const ProfitLossReportSetEndDateEvent(this.endDate);
  final DateTime endDate;

  @override
  List<Object?> get props => [endDate];
}

class ProfitLossReportSetGroupByEvent extends ProfitLossReportEvent {
  const ProfitLossReportSetGroupByEvent(this.groupBy);
  final ProfitLossGroupBy groupBy;

  @override
  List<Object?> get props => [groupBy];
}

class ProfitLossReportSetSortByEvent extends ProfitLossReportEvent {
  const ProfitLossReportSetSortByEvent(this.sortBy);
  final ProfitLossSortBy sortBy;

  @override
  List<Object?> get props => [sortBy];
}

class ProfitLossReportSetOverlayEvent extends ProfitLossReportEvent {
  const ProfitLossReportSetOverlayEvent(this.overlayEntry);
  final OverlayEntry? overlayEntry;

  @override
  List<Object?> get props => [overlayEntry];
}

class ProfitLossReportRemoveOverlayEvent extends ProfitLossReportEvent {
  const ProfitLossReportRemoveOverlayEvent();
}

class ProfitLossReportUpdateProductsEvent extends ProfitLossReportEvent {
  const ProfitLossReportUpdateProductsEvent(this.products);
  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

class ProfitLossReportUpdateInvoicesEvent extends ProfitLossReportEvent {
  const ProfitLossReportUpdateInvoicesEvent(this.invoices);
  final List<Invoice> invoices;

  @override
  List<Object?> get props => [invoices];
}

class ProfitLossReportUpdateInvoiceProductsEvent extends ProfitLossReportEvent {
  const ProfitLossReportUpdateInvoiceProductsEvent(this.invoiceProducts);
  final List<InvoiceProduct> invoiceProducts;

  @override
  List<Object?> get props => [invoiceProducts];
}

class ProfitLossReportUpdateOrdersEvent extends ProfitLossReportEvent {
  const ProfitLossReportUpdateOrdersEvent(this.orders);
  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

class ProfitLossReportUpdateOrderProductsEvent extends ProfitLossReportEvent {
  const ProfitLossReportUpdateOrderProductsEvent(this.orderProducts);
  final List<OrderProduct> orderProducts;

  @override
  List<Object?> get props => [orderProducts];
}

class ProfitLossReportSetTakeEvent extends ProfitLossReportEvent {
  const ProfitLossReportSetTakeEvent(this.take);
  final int take;

  @override
  List<Object?> get props => [take];
}
