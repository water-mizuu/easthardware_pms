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

class InventoryReportSetOverlayEvent extends InventoryReportEvent {
  const InventoryReportSetOverlayEvent(this.overlayEntry);

  final OverlayEntry? overlayEntry;

  @override
  List<Object?> get props => [overlayEntry];
}

class InventoryReportRemoveOverlayEvent extends InventoryReportEvent {
  const InventoryReportRemoveOverlayEvent();
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
