import 'package:easthardware_pms/data/database/tables/orders_table.dart';
import 'package:easthardware_pms/data/database/tables/products_table.dart';
import 'package:easthardware_pms/data/database/tables/units_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Represents the list of products in a restock order
/// If [ORDER_ITEMS_SECONDARY_UNIT] is null, main unit will be used, or conversion will be set to 1.
/// [ORDER_ITEMS_PRODUCT] can be null for the cases the user purchase products not in the system.
class OrderItemsTable {
  static const String TABLE_NAME = 'ORDER_ITEMS';
  static const String ORDER_ITEMS_ID = 'id';
  static const String ORDER_ITEMS_ORDER_ID = 'order_id';
  static const String ORDER_ITEMS_NAME = 'name';
  static const String ORDER_ITEMS_DESCRIPTION = 'description';
  static const String ORDER_ITEMS_QUANTITY = 'quantity';
  static const String ORDER_ITEMS_RATE = 'rate';
  static const String ORDER_ITEMS_AMOUNT = 'amount';

  static Future<void> createTable(DatabaseExecutor database) async {
    await database.execute('''
  CREATE TABLE $TABLE_NAME (
    $ORDER_ITEMS_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    $ORDER_ITEMS_ORDER_ID INTEGER NOT NULL,
    $ORDER_ITEMS_NAME TEXT NOT NULL,
    $ORDER_ITEMS_DESCRIPTION TEXT,
    $ORDER_ITEMS_QUANTITY REAL NOT NULL,
    $ORDER_ITEMS_RATE REAL NOT NULL,
    $ORDER_ITEMS_AMOUNT REAL NOT NULL,
    FOREIGN KEY($ORDER_ITEMS_ORDER_ID) REFERENCES ${OrdersTable.ORDERS_TABLE_NAME}(${OrdersTable.ORDERS_ID})
  )
''');
  }

  static Future<void> dropTable(DatabaseExecutor database) async {
    await database.execute('DROP TABLE IF EXISTS $TABLE_NAME');
  }
}
