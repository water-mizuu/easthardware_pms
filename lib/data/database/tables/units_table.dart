import 'package:easthardware_pms/data/database/tables/products_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class UnitsTable {
  static const String UNITS_TABLE_NAME = 'units';
  static const String UNITS_ID = 'id';
  static const String UNITS_NAME = 'name';
  static const String UNITS_PRODUCT_ID = 'product_id';
  static const String UNITS_MAIN_QUANTITY = 'main_quantity';
  static const String UNITS_UNIT_QUANTITY = 'unit_quantity';

  static Future<void> createTable(DatabaseExecutor database) async {
    await database.execute('''
    CREATE TABLE $UNITS_TABLE_NAME (
    $UNITS_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    $UNITS_NAME TEXT NOT NULL,
    $UNITS_PRODUCT_ID INTEGER NOT NULL,
    $UNITS_MAIN_QUANTITY INTEGER NOT NULL,
    $UNITS_UNIT_QUANTITY INTEGER NOT NULL,
    FOREIGN KEY($UNITS_PRODUCT_ID) REFERENCES ${ProductsTable.PRODUCTS_TABLE_NAME}(${ProductsTable.PRODUCTS_ID})
    )
    ''');
  }

  static Future<void> dropTable(DatabaseExecutor database) async {
    await database.execute('DROP TABLE IF EXISTS $UNITS_TABLE_NAME');
  }
}
