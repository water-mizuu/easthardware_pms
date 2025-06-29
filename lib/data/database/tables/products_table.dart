import 'package:easthardware_pms/data/database/tables/categories_table.dart';
import 'package:easthardware_pms/data/database/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ProductsTable {
  static const String PRODUCTS_TABLE_NAME = 'products';
  static const String PRODUCTS_ID = 'id';
  static const String PRODUCTS_NAME = 'name';
  static const String PRODUCTS_SKU = 'sku';
  static const String PRODUCTS_CATEGORY = 'category';
  static const String PRODUCTS_DESCRIPTION = 'description';
  static const String PRODUCTS_SALE_PRICE = 'sale_price';
  static const String PRODUCTS_ORDER_COST = 'order_cost';
  static const String PRODUCTS_QUANTITY = 'quantity';
  static const String PRODUCTS_MAIN_UNIT = 'main_unit';
  static const String PRODUCTS_MIN_REORDER_DELAY = 'min_reorder_delay';
  static const String PRODUCTS_MAX_REORDER_DELAY = 'max_reorder_delay';
  static const String PRODUCTS_DEAD_STOCK_THRESHOLD = 'dead_stock_threshold';
  static const String PRODUCTS_FAST_MOVING_THRESHOLD = 'fast_moving_threshold';
  static const String PRODUCTS_CREATION_DATE = 'creation_date';
  static const String PRODUCTS_CREATOR_ID = 'creator_id';
  static const String PRODUCTS_ARCHIVE_STATUS = 'archive_status';

  static Future<void> createTable(DatabaseExecutor database) async {
    await database.execute('''
    CREATE TABLE $PRODUCTS_TABLE_NAME (
      $PRODUCTS_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $PRODUCTS_NAME TEXT NOT NULL UNIQUE,
      $PRODUCTS_SKU TEXT NOT NULL UNIQUE,
      $PRODUCTS_CATEGORY INTEGER,
      $PRODUCTS_DESCRIPTION TEXT,
      $PRODUCTS_SALE_PRICE REAL NOT NULL,
      $PRODUCTS_ORDER_COST REAL NOT NULL,
      $PRODUCTS_QUANTITY REAL NOT NULL,
      $PRODUCTS_MAIN_UNIT STRING NOT NULL,
      $PRODUCTS_MIN_REORDER_DELAY INTEGER NOT NULL,
      $PRODUCTS_MAX_REORDER_DELAY INTEGER NOT NULL,
      $PRODUCTS_DEAD_STOCK_THRESHOLD REAL NOT NULL,
      $PRODUCTS_FAST_MOVING_THRESHOLD REAL NOT NULL,
      $PRODUCTS_CREATION_DATE TEXT NOT NULL,
      $PRODUCTS_CREATOR_ID INTEGER NOT NULL,
      $PRODUCTS_ARCHIVE_STATUS INTEGER NOT NULL,
      FOREIGN KEY($PRODUCTS_CATEGORY) REFERENCES ${CategoriesTable.CATEGORIES_TABLE_NAME}(${CategoriesTable.CATEGORIES_ID}),
      FOREIGN KEY($PRODUCTS_CREATOR_ID) REFERENCES ${UsersTable.USERS_TABLE_NAME}(${UsersTable.USERS_ID})
    )
  ''');
  }

  static Future<void> dropTable(DatabaseExecutor database) async {
    await database.execute('DROP TABLE IF EXISTS $PRODUCTS_TABLE_NAME');
  }
}
