import 'package:easthardware_pms/data/database/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SecurityQuestionsTable {
  static const String SECURITY_QUESTIONS_TABLE = 'security_questions';
  static const String SECURITY_QUESTIONS_ID = 'id';
  static const String SECURITY_QUESTIONS_USER_ID = 'user_id';
  static const String SECURITY_QUESTIONS_QUESTION = 'question';
  static const String SECURITY_QUESTIONS_ANSWER = 'answer';

  static void createTable(DatabaseExecutor database) {
    database.execute('''
      CREATE TABLE IF NOT EXISTS $SECURITY_QUESTIONS_TABLE (
        $SECURITY_QUESTIONS_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        $SECURITY_QUESTIONS_USER_ID INTEGER NOT NULL,
        $SECURITY_QUESTIONS_QUESTION TEXT NOT NULL,
        $SECURITY_QUESTIONS_ANSWER TEXT NOT NULL,
        FOREIGN KEY ($SECURITY_QUESTIONS_USER_ID) REFERENCES ${UsersTable.USERS_TABLE_NAME}(${UsersTable.USERS_ID})
      )
    ''');
  }

  static void dropTable(DatabaseExecutor database) {
    database.execute('''
      DROP TABLE IF EXISTS $SECURITY_QUESTIONS_TABLE
    ''');
  }
}
