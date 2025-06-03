import 'package:easthardware_pms/data/database/tables/payment_methods_table.dart';
import 'package:easthardware_pms/data/database/tables/users_table.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Represents the status of an invoice
/// Revised from the Entity Relationship Diagram
/// Changes:
/// [INVOICES_DATE] Kept, and states when is the invoice expected to be paid
/// [INVOICES_PAYMENT_METHOD] Is now an INTEGER to reference the payment method table
/// [INVOICES_CREATION_DATE] states when the invoice is created. For User Logs
/// [INVOICES_PAYMENT_DATE] states when the invoice was paid
/// [INVOICES_CREATOR_ID] states the user that created the invoice.
class InvoicesTable {
  static const String INVOICES_TABLE_NAME = "invoices";
  static const String INVOICES_ID = 'id';
  static const String INVOICES_UID = 'uid';
  static const String INVOICES_CUSTOMER_NAME = "customer_name";
  static const String INVOICES_DATE = "invoice_date";
  static const String INVOICES_DUE_DATE = "due_date";
  static const String INVOICES_PAYMENT_METHOD = "payment_method";
  static const String INVOICES_REFERENCE_NUMBER = "reference_number";
  static const String INVOICES_MEMO = "memo";
  static const String INVOICES_DISCOUNT = "discount";
  static const String INVOICES_DISCOUNT_TYPE = "discount_type";
  static const String INVOICES_CREATION_DATE = "creation_date";
  static const String INVOICES_PAYMENT_DATE = "payment_date";
  static const String INVOICES_AMOUNT_DUE = "amount_due";
  static const String INVOICES_AMOUNT_PAID = "amount_paid";
  static const String INVOICES_CREATOR_ID = "user_id";

  static Future<void> createTable(Database database) async {
    await database.execute('''
      CREATE TABLE $INVOICES_TABLE_NAME(
      $INVOICES_ID INTEGER PRIMARY KEY AUTOINCREMENT,
      $INVOICES_UID TEXT NOT NULL,
      $INVOICES_CUSTOMER_NAME TEXT,
      $INVOICES_DATE TEXT NOT NULL,
      $INVOICES_DUE_DATE TEXT NOT NULL,
      $INVOICES_PAYMENT_METHOD INTEGER NOT NULL,
      $INVOICES_REFERENCE_NUMBER TEXT,
      $INVOICES_MEMO TEXT,
      $INVOICES_DISCOUNT REAL,
      $INVOICES_DISCOUNT_TYPE INT,
      $INVOICES_AMOUNT_DUE REAL NOT NULL,
      $INVOICES_AMOUNT_PAID REAL,
      $INVOICES_PAYMENT_DATE TEXT,
      $INVOICES_CREATION_DATE TEXT NOT NULL,
      $INVOICES_CREATOR_ID INTEGER NOT NULL,
      FOREIGN KEY($INVOICES_PAYMENT_METHOD) REFERENCES ${PaymentMethodsTable.PAYMENT_METHODS_TABLE_NAME}(${PaymentMethodsTable.PAYMENT_METHODS_ID}),
      FOREIGN KEY($INVOICES_CREATOR_ID) REFERENCES ${UsersTable.USERS_TABLE_NAME}(${UsersTable.USERS_ID})
      )
''');
  }

  static Future<void> dropTable(Database database) async {
    await database.execute('DROP TABLE IF EXISTS $INVOICES_TABLE_NAME');
  }
}
