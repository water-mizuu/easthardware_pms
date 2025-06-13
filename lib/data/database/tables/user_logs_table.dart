import 'package:easthardware_pms/data/database/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class UserLogsTable {
  static const String USER_LOGS_TABLE_NAME = 'user_logs';
  static const String USER_LOGS_LOG_ID = 'id';
  static const String USER_LOGS_UID = 'uid';
  static const String USER_LOGS_USER_ID = 'user_id';
  static const String USER_LOGS_EVENT = 'event';
  static const String USER_LOGS_EVENT_TIME = 'event_time';

  static Future<void> createTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE $USER_LOGS_TABLE_NAME (
        $USER_LOGS_LOG_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        $USER_LOGS_UID TEXT NOT NULL,
        $USER_LOGS_USER_ID INTEGER NOT NULL,
        $USER_LOGS_EVENT TEXT NOT NULL,
        $USER_LOGS_EVENT_TIME TEXT NOT NULL,
        FOREIGN KEY($USER_LOGS_USER_ID) REFERENCES ${UsersTable.USERS_TABLE_NAME}(${UsersTable.USERS_ID})
      )
    ''');
  }

  static Future<void> dropTable(DatabaseExecutor database) async {
    await database.execute('DROP TABLE IF EXISTS $USER_LOGS_TABLE_NAME');
  }
}
