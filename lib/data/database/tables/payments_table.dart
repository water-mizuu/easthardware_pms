import 'package:easthardware_pms/data/database/tables/invoices_table.dart';
import 'package:easthardware_pms/data/database/tables/payment_methods_table.dart';
import 'package:easthardware_pms/data/database/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class PaymentsTable {
  static const String PAYMENTS_TABLE_NAME = "payments";
  static const String PAYMENTS_ID = 'id';
  static const String PAYMENTS_INVOICE_ID = "invoice_id";
  static const String PAYMENTS_AMOUNT = "amount";
  static const String PAYMENTS_DATE = "payment_date";
  static const String PAYMENTS_PAYMENT_METHOD = "payment_method";
  static const String PAYMENTS_REFERENCE_NUMBER = "reference number";
  static const String PAYMENTS_CREATOR_ID = "creator_id";
  static const String PAYMENTS_CREATION_DATE = "creation_date";

  static Future<void> createTable(DatabaseExecutor database) async {
    await database.execute('''
      CREATE TABLE $PAYMENTS_TABLE_NAME(
      $PAYMENTS_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $PAYMENTS_INVOICE_ID INTEGER NOT NULL,
      $PAYMENTS_AMOUNT REAL NOT NULL,
      $PAYMENTS_DATE TEXT NOT NULL,
      $PAYMENTS_PAYMENT_METHOD INTEGER NOT NULL,
      $PAYMENTS_REFERENCE_NUMBER TEXT,
      $PAYMENTS_CREATOR_ID INTEGER NOT NULL,
      $PAYMENTS_CREATION_DATE TEXT NOT NULL,
      FOREIGN KEY($PAYMENTS_INVOICE_ID) REFERENCES ${InvoicesTable.INVOICES_TABLE_NAME}(${InvoicesTable.INVOICES_ID}),
      FOREIGN KEY($PAYMENTS_PAYMENT_METHOD) REFERENCES ${PaymentMethodsTable.PAYMENT_METHODS_TABLE_NAME}(${PaymentMethodsTable.PAYMENT_METHODS_ID}),
      FOREIGN KEY($PAYMENTS_CREATOR_ID) REFERENCES ${UsersTable.USERS_TABLE_NAME}(${UsersTable.USERS_ID}
      )
    ''');
  }

  static Future<void> dropTable(DatabaseExecutor database) async {
    await database.execute('DROP TABLE IF EXISTS $PAYMENTS_TABLE_NAME');
  }
}
