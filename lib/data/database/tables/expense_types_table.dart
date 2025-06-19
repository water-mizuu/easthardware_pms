import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ExpenseTypesTable {
  static const String EXPENSE_TYPE_TABLE_NAME = 'expense_types';
  static const String EXPENSE_TYPE_ID = 'id';
  static const String EXPENSE_TYPE_NAME = 'name';
  static const String EXPENSE_TYPE_ARCHIVE_STATUS = 'archive_status';

  static Future<void> createTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE $EXPENSE_TYPE_TABLE_NAME (
        $EXPENSE_TYPE_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        $EXPENSE_TYPE_NAME TEXT NOT NULL UNIQUE,
        $EXPENSE_TYPE_ARCHIVE_STATUS INTEGER DEFAULT 0
      )
    ''');

    await database.insert(
      'expense_types',
      ExpenseType(name: 'Inventory Restock').toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  static Future<void> dropTable(DatabaseExecutor database) async {
    await database.execute('DROP TABLE IF EXISTS $EXPENSE_TYPE_TABLE_NAME');
  }
}
