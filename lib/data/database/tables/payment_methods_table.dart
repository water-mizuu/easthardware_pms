import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PaymentMethodsTable {
  static const String PAYMENT_METHODS_TABLE_NAME = 'payment_methods';
  static const String PAYMENT_METHODS_ID = 'id';
  static const String PAYMENT_METHODS_NAME = 'name';

  static Future<void> createTable(Database database) async {
    await database.execute('''
      CREATE TABLE $PAYMENT_METHODS_TABLE_NAME(
        $PAYMENT_METHODS_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        $PAYMENT_METHODS_NAME TEXT NOT NULL
      )
    ''');
  }

  static Future<void> dropTable(Database database) async {
    await database.execute('DROP TABLE IF EXISTS $PAYMENT_METHODS_TABLE_NAME');
  }
}
