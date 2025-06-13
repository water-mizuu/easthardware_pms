import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async_queue/async_queue.dart';
import 'package:easthardware_pms/data/database/dao/user_logs_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
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
import 'package:easthardware_pms/domain/backend/utils/isolate_indicator.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/models/user_log.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final AsyncQueue _dbMethodQueue = AsyncQueue.autoStart();

Future<DatabaseHelper> getWebSocketDatabaseHelper(int? savedHeartbeat) async {
  assertChildIsolate();
  final database = await _getDatabase(savedHeartbeat);

  return DirectDatabaseHelper(database);
}

Future<void> resetDatabase() async {
  assertChildIsolate();
  if (kDebugMode) {
    if (_databaseInstance case final db?) {
      await db.transaction((txn) async {
        // Drop all tables
        CategoriesTable.dropTable(txn);
        ExpenseTypesTable.dropTable(txn);
        PaymentMethodsTable.dropTable(txn);
        UsersTable.dropTable(txn);
        UserLogsTable.dropTable(txn);
        ProductsTable.dropTable(txn);
        UnitsTable.dropTable(txn);
        OrdersTable.dropTable(txn);
        OrderProductsTable.dropTable(txn);
        InvoicesTable.dropTable(txn);
        InvoiceProductsTable.dropTable(txn);
        SecurityQuestionsTable.dropTable(txn);
        ProductFlagsView.dropView(txn);

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
      });
    }
  }
}

/// Handles JSON encoded database method calls.
/// Each job is executed sequentially in calling order, backed by an [AsyncQueue].
Future<DatabaseMethodResult> serverHandleDatabaseMethod(
  String method,
  List<Object?> arguments,
  int? savedHeartbeat,
) async {
  // Create a database instance or use an existing one
  assertChildIsolate();
  final start = DateTime.now();
  final completer = Completer<DatabaseMethodResult>.sync();
  _dbMethodQueue.addJob((_) async {
    final isolateDatabase = await _getDatabase(savedHeartbeat);
    final waitingDuration = DateTime.now().difference(start);

    DatabaseMethodResult? jobResult;
    try {
      switch ((method, arguments)) {
        case (
            'delete',
            [
              final String table,
              {'where': final String? where, 'whereArgs': final List<Object?>? whereArgs}
            ]
          ):
          final result = await isolateDatabase.delete(table, where: where, whereArgs: whereArgs);
          final hasChanged = result > 0;
          jobResult = DatabaseMethodResult(result: result, hasChanged: hasChanged);
          break;

        case ('execute', [final String sql, final List<Object?>? sqlArgs]):
          await isolateDatabase.execute(sql, sqlArgs);
          // Execute doesn't return a count, but we assume it modified the database
          jobResult = const DatabaseMethodResult(result: null, hasChanged: true);
          break;

        case (
            'insert',
            [
              final String table,
              final Map<String, Object?> values,
              {
                'nullColumnHack': final String? nullColumnHack,
                'conflictAlgorithm': final int? conflictAlgorithm
              }
            ]
          ):
          final result = await isolateDatabase.insert(
            table,
            values,
            nullColumnHack: nullColumnHack,
            conflictAlgorithm: conflictAlgorithm != null //
                ? ConflictAlgorithm.values[conflictAlgorithm]
                : null,
          );
          final hasChanged = result > 0;
          jobResult = DatabaseMethodResult(result: result, hasChanged: hasChanged);
          break;

        case (
            'query',
            [
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
            ]
          ):
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
          jobResult = DatabaseMethodResult(result: result, hasChanged: false);
          break;

        case (
            'queryCursor',
            [
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
            ]
          ):
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
          jobResult = DatabaseMethodResult(result: result, hasChanged: false);
          break;

        case ('rawDelete', [final String sql, final List<Object?>? args]):
          final result = await isolateDatabase.rawDelete(sql, args);
          final hasChanged = result > 0;
          jobResult = DatabaseMethodResult(result: result, hasChanged: hasChanged);
          break;

        case ('rawInsert', [final String sql, final List<Object?>? args]):
          final result = await isolateDatabase.rawInsert(sql, args);
          final hasChanged = result > 0;
          jobResult = DatabaseMethodResult(result: result, hasChanged: hasChanged);
          break;

        case ('rawQuery', [final String sql, final List<Object?>? args]):
          final result = await isolateDatabase.rawQuery(sql, args);
          // Query operations don't modify the database
          jobResult = DatabaseMethodResult(result: result, hasChanged: false);
          break;

        case (
            'rawQueryCursor',
            [final String sql, final List<Object?>? args, {'bufferSize': final int? bufferSize}]
          ):
          final result = await isolateDatabase.rawQueryCursor(sql, args, bufferSize: bufferSize);
          // Query operations don't modify the database
          jobResult = DatabaseMethodResult(result: result, hasChanged: false);
          break;

        case ('rawUpdate', [final String sql, final List<Object?>? args]):
          final result = await isolateDatabase.rawUpdate(sql, args);
          final hasChanged = result > 0;
          jobResult = DatabaseMethodResult(result: result, hasChanged: hasChanged);
          break;

        case ('rawUpdate', [final String sql]):
          final result = await isolateDatabase.rawUpdate(sql);
          final hasChanged = result > 0;
          jobResult = DatabaseMethodResult(result: result, hasChanged: hasChanged);
          break;

        case (
            'update',
            [
              final String table,
              final Map<String, Object?> values,
              {
                'where': final String? where,
                'whereArgs': final List<Object?>? whereArgs,
                'conflictAlgorithm': final int? conflictAlgorithm,
              }
            ]
          ):
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
          jobResult = DatabaseMethodResult(result: result, hasChanged: hasChanged);
          break;

        case (
            'batch.commit',
            [
              final List<Object> operations,
              {
                'exclusive': final bool? exclusive,
                'noResult': final bool? noResult,
                'continueOnError': final bool? continueOnError,
              }
            ]
          ):
          jobResult = await _executeBatch(
            isolateDatabase,
            operations,
            exclusive,
            noResult,
            continueOnError,
            isCommit: true,
          );
          break;

        case (
            'batch.apply',
            [
              final List<Object> operations,
              {'noResult': final bool? noResult, 'continueOnError': final bool? continueOnError}
            ]
          ):
          jobResult = await _executeBatch(
            isolateDatabase,
            operations,
            null, // exclusive not used for apply
            noResult,
            continueOnError,
            isCommit: false,
          );
          break;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        printBoxed(
          "Error occurred while executing database method: $method\n"
              "Error: $e\n"
              "Stack Trace: $stackTrace",
          "Database Method Call",
        );
      }
      completer.completeError(e, stackTrace);
      return;
    }

    final turnAroundDuration = DateTime.now().difference(start);
    if (kDebugMode) {
      printBoxed(
        "Method: '$method'\n"
            "Waiting Time: ${waitingDuration.inMicroseconds}μs\n"
            "Turnaround Time: ${turnAroundDuration.inMicroseconds}μs\n"
            "Arguments:\n${jsonEncode(arguments).wrap.indent}",
        "Database Method Call",
      );
    }

    if (jobResult != null) {
      completer.complete(jobResult);
    } else {
      completer.completeError(
        UnsupportedError(
          'Unsupported database method: $method or ' //
          'invalid arguments: $arguments',
        ),
      );
    }
  });

  return completer.future;
}

// Database instance cache
Database? _databaseInstance;

/// The creation of the database instance is here.
///   It is created after a server isolate is spawned.
Future<Database> _getDatabase(int? savedHeartbeat) async {
  assertChildIsolate();
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
      onOpen: (db) async {
        /// Regardless of the database version, we reset the login status for all users.

        if (savedHeartbeat == null) {
          // Reset the login status for the user
          await db.update(
            UsersTable.USERS_TABLE_NAME,
            {UsersTable.USERS_LOGIN_STATUS: 0}, // Reset login status
            where: '${UsersTable.USERS_LOGIN_STATUS} = ?',
            whereArgs: [1],
          );

          return;
        }

        final loggedInUsers = await db.query(
          UsersTable.USERS_TABLE_NAME,
          where: '${UsersTable.USERS_LOGIN_STATUS} = ?',
          whereArgs: [1], // Assuming 1 is the logged-in status
        );
        if (loggedInUsers.isEmpty) return;

        final databaseHelper = DirectDatabaseHelper(db);
        final userLogsDao = UserLogsDao(databaseHelper);
        final lastHeartbeat = DateTime.fromMillisecondsSinceEpoch(savedHeartbeat);
        for (final userMap in loggedInUsers) {
          await userLogsDao.insertUserLog(
            UserLog.logout(user: User.fromMap(userMap), eventTime: lastHeartbeat),
          );
        }

        await db.update(
          UsersTable.USERS_TABLE_NAME,
          {UsersTable.USERS_LOGIN_STATUS: 0}, // Reset login status
          where: '${UsersTable.USERS_LOGIN_STATUS} = ?',
          whereArgs: [1],
        );
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
  assertChildIsolate();
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

extension type const DatabaseMethodResult._((Object? result, bool hasChanged) record) {
  const DatabaseMethodResult({
    required Object? result,
    required bool hasChanged,
  }) : this._((result, hasChanged));

  Object? get result => record.$1;
  bool get hasChanged => record.$2;
}
