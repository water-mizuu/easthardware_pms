import 'package:easthardware_pms/data/database/tables/invoices_table.dart';
import 'package:easthardware_pms/data/database/tables/products_table.dart';
import 'package:easthardware_pms/data/database/tables/units_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Represents the List of Products an Invoice Contains
class InvoiceProductsTable {
  static const String INVOICE_PRODUCTS_TABLE_NAME = 'invoice_products';
  static const String INVOICE_PRODUCTS_ID = 'id';
  static const String INVOICE_PRODUCTS_INVOICE = 'invoice_id';
  static const String INVOICE_PRODUCTS_PRODUCT = 'product_id';
  static const String INVOICE_PRODUCTS_NAME = 'product_name';
  static const String INVOICE_PRODUCTS_DESCRIPTION = 'description';
  static const String INVOICE_PRODUCTS_QUANTITY = 'quantity';
  static const String INVOICE_PRODUCTS_SECONDARY_UNIT = 'secondary_unit';
  static const String INVOICE_PRODUCTS_CONVERSION_FACTOR = 'conversion_factor';
  static const String INVOICE_PRODUCTS_RATE = 'rate';
  static const String INVOICE_PRODUCTS_AMOUNT = 'amount';

  static Future<void> createTable(DatabaseExecutor database) async {
    await database.execute('''
  CREATE TABLE $INVOICE_PRODUCTS_TABLE_NAME (
  $INVOICE_PRODUCTS_ID INTEGER PRIMARY KEY AUTOINCREMENT,
  $INVOICE_PRODUCTS_INVOICE INTEGER NOT NULL,
  $INVOICE_PRODUCTS_PRODUCT INTEGER NOT NULL,
  $INVOICE_PRODUCTS_NAME TEXT NOT NULL,
  $INVOICE_PRODUCTS_DESCRIPTION TEXT,
  $INVOICE_PRODUCTS_QUANTITY INTEGER NOT NULL,
  $INVOICE_PRODUCTS_SECONDARY_UNIT INTEGER,
  $INVOICE_PRODUCTS_CONVERSION_FACTOR REAL,
  $INVOICE_PRODUCTS_RATE REAL NOT NULL,
  $INVOICE_PRODUCTS_AMOUNT REAL NOT NULL,
  FOREIGN KEY($INVOICE_PRODUCTS_INVOICE) REFERENCES ${InvoicesTable.INVOICES_TABLE_NAME}(${InvoicesTable.INVOICES_ID}),
  FOREIGN KEY($INVOICE_PRODUCTS_PRODUCT) REFERENCES ${ProductsTable.PRODUCTS_TABLE_NAME}(${ProductsTable.PRODUCTS_ID}),
  FOREIGN KEY($INVOICE_PRODUCTS_SECONDARY_UNIT) REFERENCES ${UnitsTable.UNITS_TABLE_NAME}(${UnitsTable.UNITS_ID})
  )
''');
  }

  static Future<void> dropTable(DatabaseExecutor database) async {
    await database.execute('DROP TABLE IF EXISTS $INVOICE_PRODUCTS_TABLE_NAME');
  }
}
