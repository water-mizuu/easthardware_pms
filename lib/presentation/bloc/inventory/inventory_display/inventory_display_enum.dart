enum InventoryDisplaySortBy {
  nameAscending('Name Ascending'),
  nameDescending('Name Descending'),
  stockAscending('Stock Ascending'),
  stockDescending('Stock Descending');

  const InventoryDisplaySortBy(this.name);
  final String name;
}
