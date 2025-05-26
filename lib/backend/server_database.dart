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

    final path = join(await getDatabasesPath(), 'server_return database.db');
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

  bool hasModifyingOperations = false;

  for (final op in operations) {
    switch (op) {
      case [String method, Object? params]:
        switch (method) {
          case 'rawInsert':
            if (params case [String sql, List<Object?>? arguments]) {
              batch.rawInsert(sql, arguments);
              hasModifyingOperations = true;
            }
            break;

          case 'insert':
            if (params
                case [
                  String table,
                  Map<String, Object?> values,
                  {
                    'nullColumnHack': String? nullColumnHack,
                    'conflictAlgorithm': int? conflictAlgorithm
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
            if (params case [String sql, List<Object?>? arguments]) {
              batch.rawUpdate(sql, arguments);
              hasModifyingOperations = true;
            }
            break;

          case 'update':
            if (params
                case [
                  String table,
                  Map<String, Object?> values,
                  {
                    'where': String? where,
                    'whereArgs': List<Object?>? whereArgs,
                    'conflictAlgorithm': int? conflictAlgorithm,
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
            if (params case [String sql, List<Object?>? arguments]) {
              batch.rawDelete(sql, arguments);
              hasModifyingOperations = true;
            }
            break;

          case 'delete':
            if (params
                case [
                  String table,
                  {'where': String? where, 'whereArgs': List<Object?>? whereArgs}
                ]) {
              batch.delete(table, where: where, whereArgs: whereArgs);
              hasModifyingOperations = true;
            }
            break;

          case 'execute':
            if (params case [String sql, List<Object?>? arguments]) {
              batch.execute(sql, arguments);
              hasModifyingOperations = true;
            }
            break;

          case 'query':
            if (params
                case [
                  String table,
                  {
                    'distinct': bool? distinct,
                    'columns': List<String>? columns,
                    'where': String? where,
                    'whereArgs': List<Object?>? whereArgs,
                    'groupBy': String? groupBy,
                    'having': String? having,
                    'orderBy': String? orderBy,
                    'limit': int? limit,
                    'offset': int? offset,
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
            if (params case [String sql, List<Object?>? arguments]) {
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
            String table,
            {'where': String? where, 'whereArgs': List<Object?>? whereArgs},
          ]) {
        var result = await isolateDatabase.delete(table, where: where, whereArgs: whereArgs);
        var hasChanged = result > 0;

        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      }
      break;

    case 'execute':
      if (arguments case [String sql, List<Object?>? sqlArgs]) {
        await isolateDatabase.execute(sql, sqlArgs);
        // Execute doesn't return a count, but we assume it modified the database
        return DatabaseMethodResult(result: null, hasChanged: true);
      }
      break;

    case 'insert':
      if (arguments
          case [
            String table,
            Map<String, Object?> values,
            {'nullColumnHack': String? nullColumnHack, 'conflictAlgorithm': int? conflictAlgorithm}
          ]) {
        var result = await isolateDatabase.insert(
          table,
          values,
          nullColumnHack: nullColumnHack,
          conflictAlgorithm: conflictAlgorithm != null //
              ? ConflictAlgorithm.values[conflictAlgorithm]
              : null,
        );
        var hasChanged = result > 0;

        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      }
      break;

    case 'query':
      if (arguments
          case [
            String table,
            {
              'distinct': bool? distinct,
              'columns': List<String>? columns,
              'where': String? where,
              'whereArgs': List<Object?>? whereArgs,
              'groupBy': String? groupBy,
              'having': String? having,
              'orderBy': String? orderBy,
              'limit': int? limit,
              'offset': int? offset,
            }
          ]) {
        var result = await isolateDatabase.query(
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
            String table,
            {
              'distinct': bool? distinct,
              'columns': List<String>? columns,
              'where': String? where,
              'whereArgs': List<Object?>? whereArgs,
              'groupBy': String? groupBy,
              'having': String? having,
              'orderBy': String? orderBy,
              'limit': int? limit,
              'offset': int? offset,
              'bufferSize': int? bufferSize,
            }
          ]) {
        var result = await isolateDatabase.queryCursor(
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
      if (arguments case [String sql, List<Object?>? args]) {
        var result = await isolateDatabase.rawDelete(sql, args);
        var hasChanged = result > 0;
        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      } else if (arguments case [String sql]) {
        var result = await isolateDatabase.rawDelete(sql);
        var hasChanged = result > 0;
        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      }
      break;

    case 'rawInsert':
      if (arguments case [String sql, List<Object?>? args]) {
        var result = await isolateDatabase.rawInsert(sql, args);
        var hasChanged = result > 0;
        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      } else if (arguments case [String sql]) {
        var result = await isolateDatabase.rawInsert(sql);
        var hasChanged = result > 0;
        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      }
      break;

    case 'rawQuery':
      if (arguments case [String sql, List<Object?>? args]) {
        var result = await isolateDatabase.rawQuery(sql, args);
        // Query operations don't modify the database
        return DatabaseMethodResult(result: result, hasChanged: false);
      } else if (arguments case [String sql]) {
        var result = await isolateDatabase.rawQuery(sql);
        // Query operations don't modify the database
        return DatabaseMethodResult(result: result, hasChanged: false);
      }
      break;

    case 'rawQueryCursor':
      if (arguments case [String sql, List<Object?>? args, {'bufferSize': int? bufferSize}]) {
        var result = await isolateDatabase.rawQueryCursor(sql, args, bufferSize: bufferSize);
        // Query operations don't modify the database
        return DatabaseMethodResult(result: result, hasChanged: false);
      }
      break;

    case 'rawUpdate':
      if (arguments case [String sql, List<Object?>? args]) {
        var result = await isolateDatabase.rawUpdate(sql, args);
        var hasChanged = result > 0;
        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      } else if (arguments case [String sql]) {
        var result = await isolateDatabase.rawUpdate(sql);
        var hasChanged = result > 0;
        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      }
      break;

    case 'update':
      if (arguments
          case [
            String table,
            Map<String, Object?> values,
            {
              'where': String? where,
              'whereArgs': List<Object?>? whereArgs,
              'conflictAlgorithm': int? conflictAlgorithm,
            }
          ]) {
        var result = await isolateDatabase.update(
          table,
          values,
          where: where,
          whereArgs: whereArgs,
          conflictAlgorithm: conflictAlgorithm != null //
              ? ConflictAlgorithm.values[conflictAlgorithm]
              : null,
        );
        var hasChanged = result > 0;

        return DatabaseMethodResult(result: result, hasChanged: hasChanged);
      }
      break;

    case 'batch.commit':
      if (arguments
          case [
            List<Object> operations,
            {
              'exclusive': bool? exclusive,
              'noResult': bool? noResult,
              'continueOnError': bool? continueOnError,
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
            List<Object> operations,
            {'noResult': bool? noResult, 'continueOnError': bool? continueOnError}
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

class DatabaseMethodResult {
  final dynamic result;
  final bool hasChanged;

  DatabaseMethodResult({required this.result, required this.hasChanged});

  @override
  String toString() {
    return 'DatabaseMethodResult(result: $result, hasChanged: $hasChanged)';
  }
}
