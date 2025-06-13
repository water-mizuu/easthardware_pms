import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ExpenseTypesTable {
  static const String EXPENSE_TYPE_TABLE_NAME = 'expense_types';
  static const String EXPENSE_TYPE_ID = 'id';
  static const String EXPENSE_TYPE_NAME = 'name';

  static void createTable(DatabaseExecutor database) {
    database.execute('''
      CREATE TABLE $EXPENSE_TYPE_TABLE_NAME (
        $EXPENSE_TYPE_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        $EXPENSE_TYPE_NAME TEXT NOT NULL UNIQUE
      )
    ''');
  }

  static Future<void> dropTable(DatabaseExecutor database) async {
    await database.execute('DROP TABLE IF EXISTS $EXPENSE_TYPE_TABLE_NAME');
  }
}
