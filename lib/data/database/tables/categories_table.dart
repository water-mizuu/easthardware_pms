import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class CategoriesTable {
  static const String CATEGORIES_TABLE_NAME = "categories";
  static const String CATEGORIES_ID = "id";
  static const String CATEGORIES_NAME = "name";
  static const String CATEGORIES_ARCHIVE_STATUS = "archive_status";

  static Future<void> createTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE $CATEGORIES_TABLE_NAME (
        $CATEGORIES_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        $CATEGORIES_NAME TEXT NOT NULL UNIQUE
        $CATEGORIES_ARCHIVE_STATUS INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<void> dropTable(DatabaseExecutor database) async {
    await database.execute('DROP TABLE IF EXISTS $CATEGORIES_TABLE_NAME');
  }
}
