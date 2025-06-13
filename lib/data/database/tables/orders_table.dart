import 'package:easthardware_pms/data/database/tables/expense_types_table.dart';
import 'package:easthardware_pms/data/database/tables/payment_methods_table.dart';
import 'package:easthardware_pms/data/database/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class OrdersTable {
  static const String ORDERS_TABLE_NAME = 'orders';
  static const String ORDERS_ID = 'id';
  static const String ORDERS_UID = 'uid';
  static const String ORDERS_PAYEE_NAME = 'payee_name';
  static const String ORDERS_EXPRENSE_TYPE = 'expense_type';
  static const String ORDERS_DATE = 'order_date';
  static const String ORDERS_PAYMENT_METHOD = 'payment_method';
  static const String ORDERS_REFERENCE_NUMBER = 'reference_number';
  static const String ORDERS_MEMO = 'memo';
  static const String ORDERS_AMOUNT_DUE = 'amount_due';
  static const String ORDERS_AMOUNT_PAID = 'amount_paid';
  static const String ORDERS_PAYMENT_DATE = 'payment_date';
  static const String ORDERS_CREATION_DATE = 'creation_date';
  static const String ORDERS_CREATOR_ID = 'creator_id';

  static void createTable(DatabaseExecutor database) {
    database.execute('''
      CREATE TABLE IF NOT EXISTS $ORDERS_TABLE_NAME (
        $ORDERS_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        $ORDERS_UID TEXT NOT NULL,
        $ORDERS_PAYEE_NAME TEXT NOT NULL,
        $ORDERS_EXPRENSE_TYPE INTEGER NOT NULL,
        $ORDERS_DATE TEXT NOT NULL,
        $ORDERS_PAYMENT_METHOD INTEGER NOT NULL,
        $ORDERS_REFERENCE_NUMBER TEXT,
        $ORDERS_MEMO TEXT,
        $ORDERS_AMOUNT_DUE REAL NOT NULL,
        $ORDERS_AMOUNT_PAID REAL,
        $ORDERS_PAYMENT_DATE TEXT,
        $ORDERS_CREATION_DATE TEXT NOT NULL,
        $ORDERS_CREATOR_ID INTEGER NOT NULL,
        FOREIGN KEY($ORDERS_EXPRENSE_TYPE) REFERENCES ${ExpenseTypesTable.EXPENSE_TYPE_TABLE_NAME}(${ExpenseTypesTable.EXPENSE_TYPE_ID}),
        FOREIGN KEY($ORDERS_PAYMENT_METHOD) REFERENCES ${PaymentMethodsTable.PAYMENT_METHODS_TABLE_NAME}(${PaymentMethodsTable.PAYMENT_METHODS_ID}),
        FOREIGN KEY($ORDERS_CREATOR_ID) REFERENCES ${UsersTable.USERS_TABLE_NAME}(${UsersTable.USERS_ID})
      )
    ''');
  }

  static void dropTable(DatabaseExecutor database) {
    database.execute('DROP TABLE IF EXISTS $ORDERS_TABLE_NAME');
  }
}
