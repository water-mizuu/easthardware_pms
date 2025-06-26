part of 'business_snapshot_report_bloc.dart';

abstract class BusinessSnapshotReportEvent extends Equatable {
  const BusinessSnapshotReportEvent();

  @override
  List<Object?> get props => [];
}

class BusinessSnapshotReportInitializeEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportInitializeEvent();
}

class BusinessSnapshotReportSetGeneratingEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportSetGeneratingEvent(this.isGenerating);

  final bool isGenerating;

  @override
  List<Object?> get props => [isGenerating];
}

class BusinessSnapshotReportSetStartDateEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportSetStartDateEvent(this.startDate);

  final DateTime startDate;

  @override
  List<Object?> get props => [startDate];
}

class BusinessSnapshotReportSetEndDateEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportSetEndDateEvent(this.endDate);

  final DateTime endDate;

  @override
  List<Object?> get props => [endDate];
}

class BusinessSnapshotReportSetComparisonPeriodEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportSetComparisonPeriodEvent(this.comparisonPeriod);

  final BusinessSnapshotPeriod comparisonPeriod;

  @override
  List<Object?> get props => [comparisonPeriod];
}

class BusinessSnapshotReportSetTopProductsSortByEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportSetTopProductsSortByEvent(this.sortBy);

  final TopSellingProductSortBy sortBy;

  @override
  List<Object?> get props => [sortBy];
}

class BusinessSnapshotReportSetExpenseBreakdownSortByEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportSetExpenseBreakdownSortByEvent(this.sortBy);

  final ExpenseBreakdownSortBy sortBy;

  @override
  List<Object?> get props => [sortBy];
}

class BusinessSnapshotReportSetKeyMetricsSortByEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportSetKeyMetricsSortByEvent(this.sortBy);

  final BusinessMetricSortBy sortBy;

  @override
  List<Object?> get props => [sortBy];
}

class BusinessSnapshotReportSetMaxTopProductsEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportSetMaxTopProductsEvent(this.maxProducts);

  final int maxProducts;

  @override
  List<Object?> get props => [maxProducts];
}

class BusinessSnapshotReportUpdateProductsEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportUpdateProductsEvent(this.products);

  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

class BusinessSnapshotReportUpdateInvoicesEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportUpdateInvoicesEvent(this.invoices);

  final List<Invoice> invoices;

  @override
  List<Object?> get props => [invoices];
}

class BusinessSnapshotReportUpdateInvoiceProductsEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportUpdateInvoiceProductsEvent(this.invoiceProducts);

  final List<InvoiceProduct> invoiceProducts;

  @override
  List<Object?> get props => [invoiceProducts];
}

class BusinessSnapshotReportUpdateOrdersEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportUpdateOrdersEvent(this.orders);

  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

class BusinessSnapshotReportUpdateOrderProductsEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportUpdateOrderProductsEvent(this.orderProducts);

  final List<OrderProduct> orderProducts;

  @override
  List<Object?> get props => [orderProducts];
}

class BusinessSnapshotReportUpdateExpenseTypesEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportUpdateExpenseTypesEvent(this.expenseTypes);

  final List<ExpenseType> expenseTypes;

  @override
  List<Object?> get props => [expenseTypes];
}

class BusinessSnapshotReportSetOverlayEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportSetOverlayEvent(this.overlayEntry);

  final OverlayEntry? overlayEntry;

  @override
  List<Object?> get props => [overlayEntry];
}

class BusinessSnapshotReportRemoveOverlayEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportRemoveOverlayEvent();
}

class BusinessSnapshotReportSetChartImageEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportSetChartImageEvent(this.chartImage);

  final Uint8List? chartImage;

  @override
  List<Object?> get props => [chartImage];
}

class BusinessSnapshotReportSetSelectedProductsEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportSetSelectedProductsEvent(this.selectedProducts);

  final List<Product> selectedProducts;

  @override
  List<Object?> get props => [selectedProducts];
}

class BusinessSnapshotReportSetSelectedCategoriesEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportSetSelectedCategoriesEvent(this.selectedCategories);

  final List<Category> selectedCategories;

  @override
  List<Object?> get props => [selectedCategories];
}

class BusinessSnapshotReportAddSelectedProductEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportAddSelectedProductEvent(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

class BusinessSnapshotReportRemoveSelectedProductEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportRemoveSelectedProductEvent(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

class BusinessSnapshotReportAddSelectedCategoryEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportAddSelectedCategoryEvent(this.category);

  final Category category;

  @override
  List<Object?> get props => [category];
}

class BusinessSnapshotReportRemoveSelectedCategoryEvent extends BusinessSnapshotReportEvent {
  const BusinessSnapshotReportRemoveSelectedCategoryEvent(this.category);

  final Category category;

  @override
  List<Object?> get props => [category];
}
