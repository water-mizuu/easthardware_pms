import 'dart:async';
import 'dart:io';

import 'package:easthardware_pms/backend/server_mode.dart';
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

@otherIsolate
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
    _databaseInstance = await openDatabase(path, version: 2, onCreate: (db, version) {
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
    }, onUpgrade: (db, _, __) async {
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
    });
  }
  return _databaseInstance!;
}

@otherIsolate
Future<List<Object?>> _executeBatch(
  Database db,
  List<Object> operations,
  bool? exclusive,
  bool? noResult,
  bool? continueOnError, {
  required bool isCommit,
}) async {
  assert(RootIsolateToken.instance == null);
  final batch = db.batch();

  for (final op in operations) {
    switch (op) {
      case [String method, Object? params]:
        switch (method) {
          case 'rawInsert':
            if (params case [String sql, List<Object?>? arguments]) {
              batch.rawInsert(sql, arguments);
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
            }
            break;

          case 'rawUpdate':
            if (params case [String sql, List<Object?>? arguments]) {
              batch.rawUpdate(sql, arguments);
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
            }
            break;

          case 'rawDelete':
            if (params case [String sql, List<Object?>? arguments]) {
              batch.rawDelete(sql, arguments);
            }
            break;

          case 'delete':
            if (params
                case [
                  String table,
                  {'where': String? where, 'whereArgs': List<Object?>? whereArgs}
                ]) {
              batch.delete(table, where: where, whereArgs: whereArgs);
            }
            break;

          case 'execute':
            if (params case [String sql, List<Object?>? arguments]) {
              batch.execute(sql, arguments);
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
            }
            break;

          case 'rawQuery':
            if (params case [String sql, List<Object?>? arguments]) {
              batch.rawQuery(sql, arguments);
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

  if (isCommit) {
    return batch.commit(exclusive: exclusive, noResult: noResult, continueOnError: continueOnError);
  } else {
    return batch.apply(noResult: noResult, continueOnError: continueOnError);
  }
}

@otherIsolate
Future<dynamic> handleDbMethod(String method, List<Object?> arguments) async {
  // Create a database instance or use an existing one
  assert(RootIsolateToken.instance == null);
  final isolateDatabase = await _getDatabase();

  switch (method) {
    case 'delete':
      if (arguments
          case [
            String table,
            {
              'where': String? where,
              'whereArgs': List<Object?>? whereArgs,
            }
          ]) {
        return isolateDatabase.delete(table, where: where, whereArgs: whereArgs);
      }
      break;

    case 'execute':
      if (arguments case [String sql, List<Object?>? sqlArgs]) {
        return isolateDatabase.execute(sql, sqlArgs);
      } else if (arguments case [String sql]) {
        return isolateDatabase.execute(sql);
      }
      break;

    case 'insert':
      if (arguments
          case [
            String table,
            Map<String, Object?> values,
            {'nullColumnHack': String? nullColumnHack, 'conflictAlgorithm': int? conflictAlgorithm}
          ]) {
        return isolateDatabase.insert(
          table,
          values,
          nullColumnHack: nullColumnHack,
          conflictAlgorithm: conflictAlgorithm != null //
              ? ConflictAlgorithm.values[conflictAlgorithm]
              : null,
        );
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
        if (kDebugMode) {
          print(arguments);
        }
        return isolateDatabase.query(
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
        return isolateDatabase.queryCursor(
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
      }
      break;

    case 'rawDelete':
      if (arguments case [String sql, List<Object?>? args]) {
        return isolateDatabase.rawDelete(sql, args);
      } else if (arguments case [String sql]) {
        return isolateDatabase.rawDelete(sql);
      }
      break;

    case 'rawInsert':
      if (arguments case [String sql, List<Object?>? args]) {
        return isolateDatabase.rawInsert(sql, args);
      } else if (arguments case [String sql]) {
        return isolateDatabase.rawInsert(sql);
      }
      break;

    case 'rawQuery':
      if (arguments case [String sql, List<Object?>? args]) {
        return isolateDatabase.rawQuery(sql, args);
      } else if (arguments case [String sql]) {
        return isolateDatabase.rawQuery(sql);
      }
      break;

    case 'rawQueryCursor':
      if (arguments case [String sql, List<Object?>? args, {'bufferSize': int? bufferSize}]) {
        return isolateDatabase.rawQueryCursor(sql, args, bufferSize: bufferSize);
      }
      break;

    case 'rawUpdate':
      if (arguments case [String sql, List<Object?>? args]) {
        return isolateDatabase.rawUpdate(sql, args);
      } else if (arguments case [String sql]) {
        return isolateDatabase.rawUpdate(sql);
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
        return isolateDatabase.update(
          table,
          values,
          where: where,
          whereArgs: whereArgs,
          conflictAlgorithm: conflictAlgorithm != null //
              ? ConflictAlgorithm.values[conflictAlgorithm]
              : null,
        );
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
