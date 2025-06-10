part of 'inventory_display_bloc.dart';

sealed class InventoryDisplayEvent {}

class InventoryDisplayItemsUpdatedEvent implements InventoryDisplayEvent {
  const InventoryDisplayItemsUpdatedEvent(this.allProducts);

  final WeakReference<List<Product>> allProducts;
}

class InventoryDisplaySearchEvent implements InventoryDisplayEvent {
  const InventoryDisplaySearchEvent(this.searchQuery);

  final String searchQuery;
}

class InventoryDisplayCategoryEvent implements InventoryDisplayEvent {
  const InventoryDisplayCategoryEvent(this.category);

  final Category? category;
}

class InventoryDisplaySortEvent implements InventoryDisplayEvent {
  const InventoryDisplaySortEvent(this.sortBy);

  final InventoryDisplaySortBy sortBy;
}

class _InventoryDisplayProcessQueryEvent implements InventoryDisplayEvent {
  const _InventoryDisplayProcessQueryEvent();
}
