import 'dart:async';

import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:easthardware_pms/data/database/tables/categories_table.dart';
import 'package:easthardware_pms/data/database/tables/expense_types_table.dart';
import 'package:easthardware_pms/data/database/tables/invoice_products_table.dart';
import 'package:easthardware_pms/data/database/tables/invoices_table.dart';
import 'package:easthardware_pms/data/database/tables/order_products_table.dart';
import 'package:easthardware_pms/data/database/tables/orders_table.dart';
import 'package:easthardware_pms/data/database/tables/payment_methods_table.dart';
import 'package:easthardware_pms/data/database/tables/products_table.dart';
import 'package:easthardware_pms/data/database/tables/security_questions_table.dart';
import 'package:easthardware_pms/data/database/tables/units_table.dart';
import 'package:easthardware_pms/data/database/tables/user_logs_table.dart';
import 'package:easthardware_pms/data/database/tables/users_table.dart';
import 'package:easthardware_pms/data/database/views/product_flags_view.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// database_helper.dart
/// This file contains the DatabaseHelper class
///
/// The DatabaseHelper class shall be responsible for creating the tables on creating, initializing, and upgrading the SQLite database.
///
/// Any data manipulation functions should be created in DAOs respective to entities.

abstract base class DatabaseHelper {
  /// Ensures there is only one instance of the database all througouht the applicaiton
  /// This avoids any conflicts from multiple connections
  DatabaseHelper([this._database]);

  final Database? _database;
  Database get database => _database!;

  Future<void> onCreate(Database database, int version) async {
    CategoriesTable.createTable(database);
    ExpenseTypesTable.createTable(database);
    PaymentMethodsTable.createTable(database);
    UsersTable.createTable(database);
    UserLogsTable.createTable(database);
    ProductsTable.createTable(database);
    UnitsTable.createTable(database);
    OrdersTable.createTable(database);
    OrderProductsTable.createTable(database);
    InvoicesTable.createTable(database);
    InvoiceProductsTable.createTable(database);
    SecurityQuestionsTable.createTable(database);
    ProductFlagsView.createView(database);
  }

  Future<void> onUpgrade(
      Database database, int oldVersion, int newVersion) async {
    // Drop all tables
    CategoriesTable.dropTable(database);
    ExpenseTypesTable.dropTable(database);
    PaymentMethodsTable.dropTable(database);
    UsersTable.dropTable(database);
    UserLogsTable.dropTable(database);
    ProductsTable.dropTable(database);
    UnitsTable.dropTable(database);
    OrdersTable.dropTable(database);
    OrderProductsTable.dropTable(database);
    InvoicesTable.dropTable(database);
    InvoiceProductsTable.dropTable(database);
    SecurityQuestionsTable.dropTable(database);
    ProductFlagsView.dropView(database);
    // Recreate all tables
    await onCreate(database, newVersion);
    // You can also add any additional migration logic here if needed
    // For example, if you want to migrate data from old tables to new tables, you can do it here
  }
}

/// TODO: Find a way to include the onCreate and onUpgrade here
///   to each database helper types
final class NullDatabaseHelper extends DatabaseHelper {
  NullDatabaseHelper() : super(null);
}

final class ServerDatabaseHelper extends DatabaseHelper {
  ServerDatabaseHelper(Server server) : super(DatabaseServerProxy(server));
}
