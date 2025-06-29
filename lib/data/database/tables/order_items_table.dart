import 'package:easthardware_pms/data/database/tables/orders_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Represents the list of items in a restock order
class OrderItemsTable {
  static const String TABLE_NAME = 'order_items';
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
        $ORDER_ITEMS_QUANTITY INTEGER NOT NULL,
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
