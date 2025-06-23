import 'package:easthardware_pms/domain/models/product.dart';

enum InventoryDisplaySortBy {
  nameAscending('Name Ascending'),
  nameDescending('Name Descending'),
  categoryAscending('Category Ascending'),
  categoryDescending('Category Descending'),
  stockAscending('Stock Ascending'),
  stockDescending('Stock Descending'),
  priceAscending('Price Ascending'),
  priceDescending('Price Descending'),
  urgencyAscending('Urgency Ascending'),
  urgencyDescending('Urgency Descending');

  const InventoryDisplaySortBy(this.name);
  final String name;

  int compareProducts(Product a, Product b) {
    final isArchivedA = a.archiveStatus == 1;
    final isArchivedB = b.archiveStatus == 1;

    if (isArchivedA && !isArchivedB) {
      return 1; // A is archived, B is not
    } else if (!isArchivedA && isArchivedB) {
      return -1; // B is archived, A is not
    }

    switch (this) {
      case InventoryDisplaySortBy.nameAscending:
        return a.name.compareTo(b.name);
      case InventoryDisplaySortBy.nameDescending:
        return b.name.compareTo(a.name);
      case InventoryDisplaySortBy.categoryAscending:
        return (a.categoryName ?? '').compareTo(b.categoryName ?? '');
      case InventoryDisplaySortBy.categoryDescending:
        return (b.categoryName ?? '').compareTo(a.categoryName ?? '');
      case InventoryDisplaySortBy.stockAscending:
        return a.quantity.compareTo(b.quantity);
      case InventoryDisplaySortBy.stockDescending:
        return b.quantity.compareTo(a.quantity);
      case InventoryDisplaySortBy.priceAscending:
        return a.salePrice.compareTo(b.salePrice);
      case InventoryDisplaySortBy.priceDescending:
        return b.salePrice.compareTo(a.salePrice);
      case InventoryDisplaySortBy.urgencyAscending:
        late final isAStockGone = a.quantity <= 0;
        late final isBStockGone = b.quantity <= 0;

        late final isAStockLow = a.isBelowCriticalLevel == true;
        late final isBStockLow = b.isBelowCriticalLevel == true;

        switch ((isAStockGone, isBStockGone)) {
          case (true, false):
            return -1;
          case (false, true):
            return 1;
          case _:
            break;
        }

        switch ((isAStockLow, isBStockLow)) {
          case (true, false):
            return -1; // A is low stock, B is not
          case (false, true):
            return 1; // B is low stock, A is not
          case _:
            break;
        }

        return a.name.compareTo(b.name); // Both are in stock, sort by name
      case InventoryDisplaySortBy.urgencyDescending:
        return -compareProducts(a, b); // Reverse urgency order
    }
  }
}
