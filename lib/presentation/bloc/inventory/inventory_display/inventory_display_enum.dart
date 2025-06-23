enum InventoryDisplaySortBy {
  nameAscending('Name Ascending'),
  nameDescending('Name Descending'),
  categoryAscending('Category Ascending'),
  categoryDescending('Category Descending'),
  stockAscending('Stock Ascending'),
  stockDescending('Stock Descending'),
  priceAscending('Price Ascending'),
  priceDescending('Price Descending'),
  urgency('Urgency');

  const InventoryDisplaySortBy(this.name);
  final String name;
}
