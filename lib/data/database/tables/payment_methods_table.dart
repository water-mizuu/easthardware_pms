import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PaymentMethodsTable {
  static const String PAYMENT_METHODS_TABLE_NAME = 'payment_methods';
  static const String PAYMENT_METHODS_ID = 'id';
  static const String PAYMENT_METHODS_NAME = 'name';
  static const String PAYMENT_METHODS_ARCHIVE_STATUS = 'archive_status';

  static Future<void> createTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE $PAYMENT_METHODS_TABLE_NAME(
        $PAYMENT_METHODS_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        $PAYMENT_METHODS_NAME TEXT NOT NULL
        $PAYMENT_METHODS_ARCHIVE_STATUS INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<void> dropTable(DatabaseExecutor database) async {
    await database.execute('DROP TABLE IF EXISTS $PAYMENT_METHODS_TABLE_NAME');
  }
}
