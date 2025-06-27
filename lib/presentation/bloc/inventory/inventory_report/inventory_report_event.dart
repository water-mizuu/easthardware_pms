part of 'inventory_report_bloc.dart';

abstract class InventoryReportEvent extends Equatable {
  const InventoryReportEvent();

  @override
  List<Object?> get props => [];
}

class InventoryReportInitializeEvent extends InventoryReportEvent {
  const InventoryReportInitializeEvent();
}

class InventoryReportSetGeneratingEvent extends InventoryReportEvent {
  const InventoryReportSetGeneratingEvent(this.isGenerating);

  final bool isGenerating;

  @override
  List<Object?> get props => [isGenerating];
}

class InventoryReportSetDateEvent extends InventoryReportEvent {
  const InventoryReportSetDateEvent(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class InventoryReportUpdateInvoicesEvent extends InventoryReportEvent {
  const InventoryReportUpdateInvoicesEvent(this.invoices);

  final List<Invoice> invoices;

  @override
  List<Object?> get props => [invoices];
}

class InventoryReportUpdateInvoiceProductsEvent extends InventoryReportEvent {
  const InventoryReportUpdateInvoiceProductsEvent(this.invoiceProducts);

  final List<InvoiceProduct> invoiceProducts;

  @override
  List<Object?> get props => [invoiceProducts];
}

class InventoryReportUpdateOrdersEvent extends InventoryReportEvent {
  const InventoryReportUpdateOrdersEvent(this.orders);

  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

class InventoryReportUpdateOrderProductsEvent extends InventoryReportEvent {
  const InventoryReportUpdateOrderProductsEvent(this.orderProducts);

  final List<OrderProduct> orderProducts;

  @override
  List<Object?> get props => [orderProducts];
}

class InventoryReportUpdateProductsEvent extends InventoryReportEvent {
  const InventoryReportUpdateProductsEvent(this.products);

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

class InventoryReportSetSortByEvent extends InventoryReportEvent {
  const InventoryReportSetSortByEvent(this.sortBy);

  final InventoryDisplaySortBy sortBy;

  @override
  List<Object?> get props => [sortBy];
}

class InventoryReportSetSearchQueryEvent extends InventoryReportEvent {
  const InventoryReportSetSearchQueryEvent(this.searchQuery);

  final String searchQuery;

  @override
  List<Object?> get props => [searchQuery];
}

class InventoryReportSetCategoryEvent extends InventoryReportEvent {
  const InventoryReportSetCategoryEvent(this.category);

  final Category? category;

  @override
  List<Object?> get props => [category];
}

class InventoryReportSetTakeEvent extends InventoryReportEvent {
  const InventoryReportSetTakeEvent(this.take);

  final int take;

  @override
  List<Object?> get props => [take];
}
