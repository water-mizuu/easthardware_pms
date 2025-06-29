part of 'sales_report_bloc.dart';

abstract class SalesReportEvent extends Equatable {
  const SalesReportEvent();

  @override
  List<Object?> get props => [];
}

class SalesReportInitializeEvent extends SalesReportEvent {
  const SalesReportInitializeEvent();
}

class SalesReportSetGeneratingEvent extends SalesReportEvent {
  const SalesReportSetGeneratingEvent(this.isGenerating);

  final bool isGenerating;

  @override
  List<Object?> get props => [isGenerating];
}

class SalesReportSetStartDateEvent extends SalesReportEvent {
  const SalesReportSetStartDateEvent(this.startDate);

  final DateTime startDate;

  @override
  List<Object?> get props => [startDate];
}

class SalesReportSetEndDateEvent extends SalesReportEvent {
  const SalesReportSetEndDateEvent(this.endDate);

  final DateTime endDate;

  @override
  List<Object?> get props => [endDate];
}

class SalesReportSetProductReportSortByEvent extends SalesReportEvent {
  const SalesReportSetProductReportSortByEvent(this.sortBy);

  final SalesByProductReportSortBy sortBy;

  @override
  List<Object?> get props => [sortBy];
}

class SalesReportSetCategoryReportSortByEvent extends SalesReportEvent {
  const SalesReportSetCategoryReportSortByEvent(this.sortBy);

  final SalesByCategoryReportSortBy sortBy;

  @override
  List<Object?> get props => [sortBy];
}

class SalesReportSetOverlayEvent extends SalesReportEvent {
  const SalesReportSetOverlayEvent(this.overlayEntry);

  final OverlayEntry? overlayEntry;

  @override
  List<Object?> get props => [overlayEntry];
}

class SalesReportRemoveOverlayEvent extends SalesReportEvent {
  const SalesReportRemoveOverlayEvent();
}

class SalesReportUpdateProductsEvent extends SalesReportEvent {
  const SalesReportUpdateProductsEvent(this.products);

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

class SalesReportUpdateInvoicesEvent extends SalesReportEvent {
  const SalesReportUpdateInvoicesEvent(this.invoices);

  final List<Invoice> invoices;

  @override
  List<Object?> get props => [invoices];
}

class SalesReportUpdateInvoiceProductsEvent extends SalesReportEvent {
  const SalesReportUpdateInvoiceProductsEvent(this.invoiceProducts);

  final List<InvoiceProduct> invoiceProducts;

  @override
  List<Object?> get props => [invoiceProducts];
}

class SalesReportUpdateOrdersEvent extends SalesReportEvent {
  const SalesReportUpdateOrdersEvent(this.orders);

  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

class SalesReportUpdateOrderProductsEvent extends SalesReportEvent {
  const SalesReportUpdateOrderProductsEvent(this.orderProducts);

  final List<OrderProduct> orderProducts;

  @override
  List<Object?> get props => [orderProducts];
}

class SalesReportSetRowLimitEvent extends SalesReportEvent {
  const SalesReportSetRowLimitEvent(this.limit);

  final int limit;

  @override
  List<Object?> get props => [limit];
}
