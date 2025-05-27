import 'package:easthardware_pms/data/database/tables/orders_table.dart';
import 'package:easthardware_pms/data/database/tables/products_table.dart';
import 'package:easthardware_pms/data/database/tables/units_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Represents the list of products in a restock order
/// If [ORDER_PRODUCTS_SECONDARY_UNIT] is null, main unit will be used, or conversion will be set to 1.
/// [ORDER_PRODUCTS_PRODUCT] can be null for the cases the user purchase products not in the system.
class OrderProductsTable {
  static const String ORDER_PRODUCTS_TABLE_NAME = 'order_products';
  static const String ORDER_PRODUCTS_ID = 'id';
  static const String ORDER_PRODUCTS_ORDER = 'order_id';
  static const String ORDER_PRODUCTS_PRODUCT = 'product_id';
  static const String ORDER_PRODUCTS_NAME = 'product_name';
  static const String ORDER_PRODUCTS_DESCRIPTION = 'description';
  static const String ORDER_PRODUCTS_QUANTITY = 'quantity';
  static const String ORDER_PRODUCTS_SECONDARY_UNIT = 'secondary_unit';
  static const String ORDER_PRODUCTS_CONVERSION_FACTOR = 'conversion_factor';
  static const String ORDER_PRODUCTS_RATE = 'rate';
  static const String ORDER_PRODUCTS_AMOUNT = 'amount';

  static Future<void> createTable(Database database) async {
    await database.execute('''
  CREATE TABLE $ORDER_PRODUCTS_TABLE_NAME (
  $ORDER_PRODUCTS_ID INTEGER PRIMARY KEY AUTOINCREMENT,
  $ORDER_PRODUCTS_ORDER INTEGER NOT NULL,
  $ORDER_PRODUCTS_PRODUCT INTEGER,
  $ORDER_PRODUCTS_NAME TEXT NOT NULL,
  $ORDER_PRODUCTS_DESCRIPTION TEXT,
  $ORDER_PRODUCTS_QUANTITY REAL NOT NULL,
  $ORDER_PRODUCTS_SECONDARY_UNIT INT,
  $ORDER_PRODUCTS_CONVERSION_FACTOR REAL,
  $ORDER_PRODUCTS_RATE REAL NOT NULL,
  $ORDER_PRODUCTS_AMOUNT REAL NOT NULL,
  FOREIGN KEY($ORDER_PRODUCTS_ORDER) REFERENCES ${OrdersTable.ORDERS_TABLE_NAME}(${OrdersTable.ORDERS_ID}),
  FOREIGN KEY($ORDER_PRODUCTS_PRODUCT) REFERENCES ${ProductsTable.PRODUCTS_TABLE_NAME}(${ProductsTable.PRODUCTS_ID}),
  FOREIGN KEY($ORDER_PRODUCTS_SECONDARY_UNIT) REFERENCES ${UnitsTable.UNITS_TABLE_NAME} (${UnitsTable.UNITS_ID})
  )
''');
  }

  static void dropTable(Database database) {
    database.execute('DROP TABLE IF EXISTS $ORDER_PRODUCTS_TABLE_NAME');
  }
}
