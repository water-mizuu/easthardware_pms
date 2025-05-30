import 'dart:async';
import 'dart:io';

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
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Handles JSON encoded database method calls.
Future<DatabaseMethodResult> serverHandleDatabaseMethod(
  String method,
  List<Object?> arguments,
) async {
  // Create a database instance or use an existing one
  assert(RootIsolateToken.instance == null);
  final isolateDatabase = await _getDatabase();

  switch (method) {
    case 'delete':
      if (arguments
          case [
            final String table,
            {'where': final String? where, 'whereArgs': final List<Object?>? whereArgs},
          ]) {
        final result = await isolateDatabase.delete(table, where: where, whereArgs: whereArgs);
        final hasChanged = result > 0;

        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      }
      break;

    case 'execute':
      if (arguments case [final String sql, final List<Object?>? sqlArgs]) {
        await isolateDatabase.execute(sql, sqlArgs);
        // Execute doesn't return a count, but we assume it modified the database
        return DatabaseMethodResult(result: null, hasChanged: true);
      }
      break;

    case 'insert':
      if (arguments
          case [
            final String table,
            final Map<String, Object?> values,
            {
              'nullColumnHack': final String? nullColumnHack,
              'conflictAlgorithm': final int? conflictAlgorithm
            }
          ]) {
        final result = await isolateDatabase.insert(
          table,
          values,
          nullColumnHack: nullColumnHack,
          conflictAlgorithm: conflictAlgorithm != null //
              ? ConflictAlgorithm.values[conflictAlgorithm]
              : null,
        );
        final hasChanged = result > 0;

        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      }
      break;

    case 'query':
      if (arguments
          case [
            final String table,
            {
              'distinct': final bool? distinct,
              'columns': final List<String>? columns,
              'where': final String? where,
              'whereArgs': final List<Object?>? whereArgs,
              'groupBy': final String? groupBy,
              'having': final String? having,
              'orderBy': final String? orderBy,
              'limit': final int? limit,
              'offset': final int? offset,
            }
          ]) {
        final result = await isolateDatabase.query(
          table,
          distinct: distinct,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        );
        // Query operations don't modify the database
        return DatabaseMethodResult(result: result, hasChanged: false);
      }
      break;

    case 'queryCursor':
      if (arguments
          case [
            final String table,
            {
              'distinct': final bool? distinct,
              'columns': final List<String>? columns,
              'where': final String? where,
              'whereArgs': final List<Object?>? whereArgs,
              'groupBy': final String? groupBy,
              'having': final String? having,
              'orderBy': final String? orderBy,
              'limit': final int? limit,
              'offset': final int? offset,
              'bufferSize': final int? bufferSize,
            }
          ]) {
        final result = await isolateDatabase.queryCursor(
          table,
          distinct: distinct,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
          bufferSize: bufferSize,
        );
        // Query operations don't modify the database
        return DatabaseMethodResult(result: result, hasChanged: false);
      }
      break;

    case 'rawDelete':
      if (arguments case [final String sql, final List<Object?>? args]) {
        final result = await isolateDatabase.rawDelete(sql, args);
        final hasChanged = result > 0;
        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      } else if (arguments case [final String sql]) {
        final result = await isolateDatabase.rawDelete(sql);
        final hasChanged = result > 0;
        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      }
      break;

    case 'rawInsert':
      if (arguments case [final String sql, final List<Object?>? args]) {
        final result = await isolateDatabase.rawInsert(sql, args);
        final hasChanged = result > 0;
        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      } else if (arguments case [final String sql]) {
        final result = await isolateDatabase.rawInsert(sql);
        final hasChanged = result > 0;
        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      }
      break;

    case 'rawQuery':
      if (arguments case [final String sql, final List<Object?>? args]) {
        final result = await isolateDatabase.rawQuery(sql, args);
        // Query operations don't modify the database
        return DatabaseMethodResult(result: result, hasChanged: false);
      } else if (arguments case [final String sql]) {
        final result = await isolateDatabase.rawQuery(sql);
        // Query operations don't modify the database
        return DatabaseMethodResult(result: result, hasChanged: false);
      }
      break;

    case 'rawQueryCursor':
      if (arguments
          case [
            final String sql,
            final List<Object?>? args,
            {'bufferSize': final int? bufferSize}
          ]) {
        final result = await isolateDatabase.rawQueryCursor(sql, args, bufferSize: bufferSize);
        // Query operations don't modify the database
        return DatabaseMethodResult(result: result, hasChanged: false);
      }
      break;

    case 'rawUpdate':
      if (arguments case [final String sql, final List<Object?>? args]) {
        final result = await isolateDatabase.rawUpdate(sql, args);
        final hasChanged = result > 0;
        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      } else if (arguments case [final String sql]) {
        final result = await isolateDatabase.rawUpdate(sql);
        final hasChanged = result > 0;
        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      }
      break;

    case 'update':
      if (arguments
          case [
            final String table,
            final Map<String, Object?> values,
            {
              'where': final String? where,
              'whereArgs': final List<Object?>? whereArgs,
              'conflictAlgorithm': final int? conflictAlgorithm,
            }
          ]) {
        final result = await isolateDatabase.update(
          table,
          values,
          where: where,
          whereArgs: whereArgs,
          conflictAlgorithm: conflictAlgorithm != null //
              ? ConflictAlgorithm.values[conflictAlgorithm]
              : null,
        );
        final hasChanged = result > 0;

        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      }
      break;

    case 'batch.commit':
      if (arguments
          case [
            final List<Object> operations,
            {
              'exclusive': final bool? exclusive,
              'noResult': final bool? noResult,
              'continueOnError': final bool? continueOnError,
            }
          ]) {
        return _executeBatch(
          isolateDatabase,
          operations,
          exclusive,
          noResult,
          continueOnError,
          isCommit: true,
        );
      }
      break;

    case 'batch.apply':
      if (arguments
          case [
            final List<Object> operations,
            {'noResult': final bool? noResult, 'continueOnError': final bool? continueOnError}
          ]) {
        return _executeBatch(
          isolateDatabase,
          operations,
          null, // exclusive not used for apply
          noResult,
          continueOnError,
          isCommit: false,
        );
      }
      break;
  }

  throw UnsupportedError('Unsupported database method: $method or invalid arguments: $arguments');
}

// Database instance cache
Database? _databaseInstance;

/// The creation of the database instance is here.
///   It is created after a server isolate is spawned.
Future<Database> _getDatabase() async {
  assert(RootIsolateToken.instance == null, "This should be called on another isolate.");
  if (_databaseInstance == null) {
    // Initialize the database - this would typically be your actual database initialization
    // For example:
    if (Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = join(await getDatabasesPath(), 'database.db');
    _databaseInstance = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) {
        CategoriesTable.createTable(db);
        ExpenseTypesTable.createTable(db);
        PaymentMethodsTable.createTable(db);
        UsersTable.createTable(db);
        UserLogsTable.createTable(db);
        ProductsTable.createTable(db);
        UnitsTable.createTable(db);
        OrdersTable.createTable(db);
        OrderProductsTable.createTable(db);
        InvoicesTable.createTable(db);
        InvoiceProductsTable.createTable(db);
        SecurityQuestionsTable.createTable(db);
        ProductFlagsView.createView(db);
      },
      onDowngrade: (db, _, __) async {
        // Drop all tables
        CategoriesTable.dropTable(db);
        ExpenseTypesTable.dropTable(db);
        PaymentMethodsTable.dropTable(db);
        UsersTable.dropTable(db);
        UserLogsTable.dropTable(db);
        ProductsTable.dropTable(db);
        UnitsTable.dropTable(db);
        OrdersTable.dropTable(db);
        OrderProductsTable.dropTable(db);
        InvoicesTable.dropTable(db);
        InvoiceProductsTable.dropTable(db);
        SecurityQuestionsTable.dropTable(db);
        ProductFlagsView.dropView(db);
        // Recreate all tables
        CategoriesTable.createTable(db);
        ExpenseTypesTable.createTable(db);
        PaymentMethodsTable.createTable(db);
        UsersTable.createTable(db);
        UserLogsTable.createTable(db);
        ProductsTable.createTable(db);
        UnitsTable.createTable(db);
        OrdersTable.createTable(db);
        OrderProductsTable.createTable(db);
        InvoicesTable.createTable(db);
        InvoiceProductsTable.createTable(db);
        SecurityQuestionsTable.createTable(db);
        ProductFlagsView.createView(db);
        // You can also add any additional migration logic here if needed
        // For example, if you want to migrate data from old tables to new tables, you can do it here
      },
      onUpgrade: (db, _, __) async {
        // Drop all tables
        CategoriesTable.dropTable(db);
        ExpenseTypesTable.dropTable(db);
        PaymentMethodsTable.dropTable(db);
        UsersTable.dropTable(db);
        UserLogsTable.dropTable(db);
        ProductsTable.dropTable(db);
        UnitsTable.dropTable(db);
        OrdersTable.dropTable(db);
        OrderProductsTable.dropTable(db);
        InvoicesTable.dropTable(db);
        InvoiceProductsTable.dropTable(db);
        SecurityQuestionsTable.dropTable(db);
        ProductFlagsView.dropView(db);
        // Recreate all tables
        CategoriesTable.createTable(db);
        ExpenseTypesTable.createTable(db);
        PaymentMethodsTable.createTable(db);
        UsersTable.createTable(db);
        UserLogsTable.createTable(db);
        ProductsTable.createTable(db);
        UnitsTable.createTable(db);
        OrdersTable.createTable(db);
        OrderProductsTable.createTable(db);
        InvoicesTable.createTable(db);
        InvoiceProductsTable.createTable(db);
        SecurityQuestionsTable.createTable(db);
        ProductFlagsView.createView(db);
        // You can also add any additional migration logic here if needed
        // For example, if you want to migrate data from old tables to new tables, you can do it here
      },
    );
  }
  return _databaseInstance!;
}

Future<DatabaseMethodResult> _executeBatch(
  Database db,
  List<Object> operations,
  bool? exclusive,
  bool? noResult,
  bool? continueOnError, {
  required bool isCommit,
}) async {
  assert(RootIsolateToken.instance == null);
  final batch = db.batch();

  var hasModifyingOperations = false;

  for (final op in operations) {
    switch (op) {
      case [final String method, final Object? params]:
        switch (method) {
          case 'rawInsert':
            if (params case [final String sql, final List<Object?>? arguments]) {
              batch.rawInsert(sql, arguments);
              hasModifyingOperations = true;
            }
            break;

          case 'insert':
            if (params
                case [
                  final String table,
                  final Map<String, Object?> values,
                  {
                    'nullColumnHack': final String? nullColumnHack,
                    'conflictAlgorithm': final int? conflictAlgorithm
                  }
                ]) {
              batch.insert(
                table,
                values,
                nullColumnHack: nullColumnHack,
                conflictAlgorithm: conflictAlgorithm != null //
                    ? ConflictAlgorithm.values[conflictAlgorithm]
                    : null,
              );
              hasModifyingOperations = true;
            }
            break;

          case 'rawUpdate':
            if (params case [final String sql, final List<Object?>? arguments]) {
              batch.rawUpdate(sql, arguments);
              hasModifyingOperations = true;
            }
            break;

          case 'update':
            if (params
                case [
                  final String table,
                  final Map<String, Object?> values,
                  {
                    'where': final String? where,
                    'whereArgs': final List<Object?>? whereArgs,
                    'conflictAlgorithm': final int? conflictAlgorithm,
                  }
                ]) {
              batch.update(
                table,
                values,
                where: where,
                whereArgs: whereArgs,
                conflictAlgorithm: conflictAlgorithm != null //
                    ? ConflictAlgorithm.values[conflictAlgorithm]
                    : null,
              );
              hasModifyingOperations = true;
            }
            break;

          case 'rawDelete':
            if (params case [final String sql, final List<Object?>? arguments]) {
              batch.rawDelete(sql, arguments);
              hasModifyingOperations = true;
            }
            break;

          case 'delete':
            if (params
                case [
                  final String table,
                  {'where': final String? where, 'whereArgs': final List<Object?>? whereArgs}
                ]) {
              batch.delete(table, where: where, whereArgs: whereArgs);
              hasModifyingOperations = true;
            }
            break;

          case 'execute':
            if (params case [final String sql, final List<Object?>? arguments]) {
              batch.execute(sql, arguments);
              hasModifyingOperations = true;
            }
            break;

          case 'query':
            if (params
                case [
                  final String table,
                  {
                    'distinct': final bool? distinct,
                    'columns': final List<String>? columns,
                    'where': final String? where,
                    'whereArgs': final List<Object?>? whereArgs,
                    'groupBy': final String? groupBy,
                    'having': final String? having,
                    'orderBy': final String? orderBy,
                    'limit': final int? limit,
                    'offset': final int? offset,
                  }
                ]) {
              batch.query(table,
                  distinct: distinct,
                  columns: columns,
                  where: where,
                  whereArgs: whereArgs,
                  groupBy: groupBy,
                  having: having,
                  orderBy: orderBy,
                  limit: limit,
                  offset: offset);
              // Query operations don't modify the database
            }
            break;

          case 'rawQuery':
            if (params case [final String sql, final List<Object?>? arguments]) {
              batch.rawQuery(sql, arguments);
              // Query operations don't modify the database
            }
            break;

          default:
            if (kDebugMode) {
              print('Unknown batch operation method: $method with params: $params');
            }
        }
        break;

      default:
        if (kDebugMode) {
          print('Unknown batch operation format: $op');
        }
    }
  }

  final result = isCommit
      ? await batch.commit(
          exclusive: exclusive,
          noResult: noResult,
          continueOnError: continueOnError,
        )
      : await batch.apply(
          noResult: noResult,
          continueOnError: continueOnError,
        );

  return DatabaseMethodResult(result: result, hasChanged: hasModifyingOperations);
}

class DatabaseMethodResult {
  DatabaseMethodResult({required this.result, required this.hasChanged});
  final dynamic result;
  final bool hasChanged;

  @override
  String toString() {
    return 'DatabaseMethodResult(result: $result, hasChanged: $hasChanged)';
  }
}
