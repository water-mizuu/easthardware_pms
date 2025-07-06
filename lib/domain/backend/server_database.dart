import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:async_queue/async_queue.dart';
import 'package:easthardware_pms/data/database/dao/user_logs_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/database/tables/categories_table.dart';
import 'package:easthardware_pms/data/database/tables/expense_types_table.dart';
import 'package:easthardware_pms/data/database/tables/invoice_products_table.dart';
import 'package:easthardware_pms/data/database/tables/invoices_table.dart';
import 'package:easthardware_pms/data/database/tables/order_items_table.dart';
import 'package:easthardware_pms/data/database/tables/order_products_table.dart';
import 'package:easthardware_pms/data/database/tables/orders_table.dart';
import 'package:easthardware_pms/data/database/tables/payment_methods_table.dart';
import 'package:easthardware_pms/data/database/tables/payments_table.dart';
import 'package:easthardware_pms/data/database/tables/products_table.dart';
import 'package:easthardware_pms/data/database/tables/security_questions_table.dart';
import 'package:easthardware_pms/data/database/tables/units_table.dart';
import 'package:easthardware_pms/data/database/tables/user_logs_table.dart';
import 'package:easthardware_pms/data/database/tables/users_table.dart';
import 'package:easthardware_pms/data/database/views/product_flags_view.dart';
import 'package:easthardware_pms/domain/backend/utils/isolate_indicator.dart';
import 'package:easthardware_pms/domain/constants/debug_constants.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/models/user_log.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final AsyncQueue _dbMethodQueue = AsyncQueue.autoStart();

/// Spawns a [DatabaseHelper] instance for the WebSocket isolate.
///   If this is called from the main isolate, it will fail an assertion.
Future<DatabaseHelper> getWebSocketDatabaseHelper(int? savedHeartbeat) async {
  assertChildIsolate();
  final database = await _getDatabase(savedHeartbeat);

  return DirectDatabaseHelper(database);
}

Future<void> resetDatabase() async {
  assertChildIsolate();
  if (isDebugMode) {
    if (_databaseInstance case final db?) {
      await db.transaction((txn) async {
        // Drop all tables
        await CategoriesTable.dropTable(txn);
        await ExpenseTypesTable.dropTable(txn);
        await PaymentMethodsTable.dropTable(txn);
        await UsersTable.dropTable(txn);
        await UserLogsTable.dropTable(txn);
        await ProductsTable.dropTable(txn);
        await UnitsTable.dropTable(txn);
        await OrdersTable.dropTable(txn);
        await OrderProductsTable.dropTable(txn);
        await OrderItemsTable.dropTable(txn);
        await InvoicesTable.dropTable(txn);
        await InvoiceProductsTable.dropTable(txn);
        await PaymentsTable.dropTable(txn);
        await SecurityQuestionsTable.dropTable(txn);
        await ProductFlagsView.dropView(txn);

        // Recreate all tables
        await CategoriesTable.createTable(txn);
        await ExpenseTypesTable.createTable(txn);
        await PaymentMethodsTable.createTable(txn);
        await UsersTable.createTable(txn);
        await UserLogsTable.createTable(txn);
        await ProductsTable.createTable(txn);
        await UnitsTable.createTable(txn);
        await OrdersTable.createTable(txn);
        await OrderProductsTable.createTable(txn);
        await OrderItemsTable.createTable(txn);
        await InvoicesTable.createTable(txn);
        await InvoiceProductsTable.createTable(txn);
        await PaymentsTable.createTable(txn);
        await SecurityQuestionsTable.createTable(txn);
        await ProductFlagsView.createView(txn);
      });
    }
  }
}

Future<String> createBackup(String key) async {
  assertChildIsolate();

  final completer = Completer<String>.sync();

  /// Pause the database. Due to the nature of the dbMethodQueue, each job is executed
  ///   sequentially in an atomic manner.
  _dbMethodQueue.addJob((_) async {
    final database = await _getDatabase(null);
    final databasePath = database.path;

    // Close the database to release lock.
    await database.close();
    _databaseInstance = null;

    final dbFile = File(databasePath);
    if (!dbFile.existsSync()) {
      throw FileSystemException("Database file does not exist at $databasePath");
    }

    final data = dbFile.readAsBytesSync();
    final encryptedData = CryptographyService.encryptSymmetricUint8List(data, key);
    final isEncrypted = key.isNotEmpty;

    assert(
      CryptographyService.decryptSymmetricUint8List(encryptedData, key).toString() ==
          data.toString(),
      "The cryptography service should work.",
    );

    final backupPath = join(
      await getDatabasesPath(),
      'backups',
      'backup${isEncrypted ? '_E' : ''}_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    File(backupPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(encryptedData, flush: true);

    if (isDebugMode) {
      printBoxed(
        "Database backup created at: $backupPath",
        "Database Backup",
      );
    }

    _databaseInstance = await _getDatabase(null);

    completer.complete(backupPath);
    return backupPath;
  });

  return completer.future;
}

Future<void> restoreBackup(String backupPath, String key) async {
  assertChildIsolate();

  final completer = Completer<void>.sync();
  _dbMethodQueue.addJob((_) async {
    try {
      final database = await _getDatabase(null);

      final activeUsers = await database.query(
        UsersTable.USERS_TABLE_NAME,
        columns: [UsersTable.USERS_ID],
        where: '${UsersTable.USERS_LOGIN_STATUS} = 1',
      );

      final backupFile = File(backupPath);

      if (!backupFile.existsSync()) {
        completer.completeError(FileSystemException("Backup file does not exist at $backupPath"));
        return;
      }

      final encryptedData = backupFile.readAsBytesSync();
      final decryptedData = CryptographyService.decryptSymmetricUint8List(encryptedData, key);

      final tempFile = File(join(await getDatabasesPath(), 'temp_restore.db'));
      try {
        /// Write the bytes to a temporary file to ensure the data is valid.
        tempFile
          ..createSync(recursive: true)
          ..writeAsBytesSync(decryptedData, flush: true);

        // Open and close the database real quick to see if it is valid
        final recoveredDb = await openDatabase(tempFile.path, onOpen: (db) async {
          // This is just to ensure the database is valid
          await db.rawQuery('SELECT * FROM sqlite_master');
        });

        await recoveredDb.close();
      } on Object catch (e) {
        printBoxed(e);
        completer.completeError(
          FileSystemException("Decrypted data is not a valid SQLite database at $backupPath"),
        );
        return;
      } finally {
        tempFile.deleteSync();
      }

      // Close the current database to release lock
      await database.close();
      _databaseInstance = null;

      // Write the decrypted data back to the database file
      final dbFile = File(database.path);
      dbFile.writeAsBytesSync(decryptedData, flush: true);

      if (isDebugMode) {
        printBoxed(
          "Database restored from backup: $backupPath",
          "Database Restore",
        );
      }

      _databaseInstance = await _getDatabase(null);
      for (final {UsersTable.USERS_ID: userId as int} in activeUsers) {
        await _databaseInstance!.update(
          UsersTable.USERS_TABLE_NAME,
          {UsersTable.USERS_LOGIN_STATUS: 1}, // Set login status to active
          where: '${UsersTable.USERS_ID} = ?',
          whereArgs: [userId],
        );
      }

      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
    }
  });

  return completer.future;
}

Future<void> deleteBackup(String backupPath) async {
  assertChildIsolate();

  final completer = Completer<void>.sync();

  _dbMethodQueue.addJob((_) async {
    final backupFile = File(backupPath);
    if (!backupFile.existsSync()) {
      completer.completeError(FileSystemException("Backup file does not exist at $backupPath"));
      return;
    }

    try {
      await backupFile.delete();
    } catch (e, st) {
      completer.completeError(e, st);
      return;
    }
    if (isDebugMode) {
      printBoxed(
        "Backup deleted: $backupPath",
        "Database Backup Deletion",
      );
    }

    completer.complete();
  });

  return completer.future;
}

Future<int> getDatabaseSize() async {
  assertChildIsolate();

  final completer = Completer<int>.sync();

  _dbMethodQueue.addJob((_) async {
    final database = await _getDatabase(null);
    final dbFile = File(database.path);

    if (!dbFile.existsSync()) {
      completer
          .completeError(FileSystemException("Database file does not exist at ${dbFile.path}"));
      return;
    }

    final size = await dbFile.length();
    if (isDebugMode) {
      printBoxed(
        "Database size: $size bytes",
        "Database Size",
      );
    }

    completer.complete(size);
  });

  return completer.future;
}

Future<List<String>> readBackups() async {
  assertChildIsolate();

  final completer = Completer<List<String>>.sync();

  _dbMethodQueue.addJob((_) async {
    final backups = <String>[];
    final backupDir = Directory(join(await getDatabasesPath(), 'backups'));
    if (backupDir.existsSync()) {
      final backupFiles = backupDir.listSync();
      for (final file in backupFiles) {
        if (file is File) {
          backups.add(file.path);
        }
      }
    }

    completer.complete(backups);
  });

  return completer.future;
}

final Map<String, DatabaseMethodResult> _resultCache = HashMap();

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
    try {
      final isolateDatabase = await _getDatabase(savedHeartbeat);
      final cacheKey = jsonEncode([method, arguments]);

      if (_resultCache[cacheKey] case final cachedResult?) {
        // If the result is cached, return it immediately
        //  This is important especially as client requests can be repeated
        //  due to database changes.
        if (printDatabaseMessages) {
          printBoxed(
            "Cached Result for Method: '$method'\n"
                "Turnaround Time: ${DateTime.now().difference(start).inMicroseconds}μs\n"
                "Arguments:\n${jsonEncode(arguments).wrap.indent}",
            "Database Method Call",
          );
        }

        completer.complete(cachedResult);
        return;
      }

      DatabaseMethodResult? jobResult;
      switch ((method, arguments)) {
        case (
            'delete',
            [
              final String table,
              {
                'where': final String? where,
                'whereArgs': final List? whereArgs,
              }
            ]
          ):
          final result = await isolateDatabase.delete(table, where: where, whereArgs: whereArgs);
          final hasChanged = result > 0;
          jobResult = DatabaseMethodResult(result: result, hasChanged: hasChanged);
          break;

        case ('execute', [final String sql, final List? sqlArgs]):
          await isolateDatabase.execute(sql, sqlArgs);
          // Execute doesn't return a count, but we assume it modified the database
          jobResult = const DatabaseMethodResult(result: null, hasChanged: true);
          break;

        case (
            'insert',
            [
              final String table,
              final Map values,
              {
                'nullColumnHack': final String? nullColumnHack,
                'conflictAlgorithm': final int? conflictAlgorithm
              }
            ]
          ):
          final result = await isolateDatabase.insert(
            table,
            values.cast(),
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
                'columns': final List? columns,
                'where': final String? where,
                'whereArgs': final List? whereArgs,
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
            columns: columns?.cast(),
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
                'columns': final List? columns,
                'where': final String? where,
                'whereArgs': final List? whereArgs,
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
            columns: columns?.cast(),
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

        case ('rawDelete', [final String sql, final List? args]):
          final result = await isolateDatabase.rawDelete(sql, args);
          final hasChanged = result > 0;
          jobResult = DatabaseMethodResult(result: result, hasChanged: hasChanged);
          break;

        case ('rawInsert', [final String sql, final List? args]):
          final result = await isolateDatabase.rawInsert(sql, args);
          final hasChanged = result > 0;
          jobResult = DatabaseMethodResult(result: result, hasChanged: hasChanged);
          break;

        case ('rawQuery', [final String sql, final List? args]):
          final result = await isolateDatabase.rawQuery(sql, args);
          // Query operations don't modify the database
          jobResult = DatabaseMethodResult(result: result, hasChanged: false);
          break;

        case (
            'rawQueryCursor',
            [final String sql, final List? args, {'bufferSize': final int? bufferSize}]
          ):
          final result = await isolateDatabase.rawQueryCursor(sql, args, bufferSize: bufferSize);
          // Query operations don't modify the database
          jobResult = DatabaseMethodResult(result: result, hasChanged: false);
          break;

        case ('rawUpdate', [final String sql, final List? args]):
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
              final Map values,
              {
                'where': final String? where,
                'whereArgs': final List? whereArgs,
                'conflictAlgorithm': final int? conflictAlgorithm,
              }
            ]
          ):
          final result = await isolateDatabase.update(
            table,
            values.cast(),
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
              final List operations,
              {
                'exclusive': final bool? exclusive,
                'noResult': final bool? noResult,
                'continueOnError': final bool? continueOnError,
              }
            ]
          ):
          jobResult = await _executeBatch(
            isolateDatabase,
            operations.cast(),
            exclusive,
            noResult,
            continueOnError,
            isCommit: true,
          );
          break;

        case (
            'batch.apply',
            [
              final List operations,
              {'noResult': final bool? noResult, 'continueOnError': final bool? continueOnError}
            ]
          ):
          jobResult = await _executeBatch(
            isolateDatabase,
            operations.cast(),
            null, // exclusive not used for apply
            noResult,
            continueOnError,
            isCommit: false,
          );
          break;
      }

      final turnAroundDuration = DateTime.now().difference(start);
      if (printDatabaseMessages) {
        printBoxed(
          "Method: '$method'\n"
              "Turnaround Time: ${turnAroundDuration.inMicroseconds}μs\n"
              "Arguments:\n${jsonEncode(arguments).wrap.indent}",
          "Database Method Call",
        );
      }

      if (jobResult != null) {
        completer.complete(jobResult);

        final (result, didUpdateDatabase) = jobResult.record;

        /// If the database updated, we just assume naively that EVERY
        ///   entry in the cache is invalid, and therefore should be recomputed
        ///   from the IO. If we allow granular cache invalidation, we could
        ///   potentially only invalidate specific entries.
        if (didUpdateDatabase) {
          _resultCache.clear();
        }

        _resultCache[cacheKey] = jobResult;
      } else {
        completer.completeError(
          UnsupportedError(
            'Unsupported database method: $method or ' //
            'invalid arguments: $arguments',
          ),
        );
      }
    } catch (e, stackTrace) {
      if (printDatabaseMessages) {
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
    printBoxed(path);
    _databaseInstance = await openDatabase(
      path,
      version: 8,
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
        OrderItemsTable.createTable(db);
        InvoicesTable.createTable(db);
        InvoiceProductsTable.createTable(db);
        PaymentsTable.createTable(db);
        SecurityQuestionsTable.createTable(db);
        ProductFlagsView.createView(db);
      },
      onDowngrade: (db, _, __) async {
        // Drop all tables
        await CategoriesTable.dropTable(db);
        await ExpenseTypesTable.dropTable(db);
        await PaymentMethodsTable.dropTable(db);
        await UsersTable.dropTable(db);
        await UserLogsTable.dropTable(db);
        await ProductsTable.dropTable(db);
        await UnitsTable.dropTable(db);
        await OrdersTable.dropTable(db);
        await OrderProductsTable.dropTable(db);
        await OrderItemsTable.dropTable(db);
        await InvoicesTable.dropTable(db);
        await InvoiceProductsTable.dropTable(db);
        await PaymentsTable.dropTable(db);
        await SecurityQuestionsTable.dropTable(db);
        await ProductFlagsView.dropView(db);
        // Recreate all tables
        await CategoriesTable.createTable(db);
        await ExpenseTypesTable.createTable(db);
        await PaymentMethodsTable.createTable(db);
        await UsersTable.createTable(db);
        await UserLogsTable.createTable(db);
        await ProductsTable.createTable(db);
        await UnitsTable.createTable(db);
        await OrdersTable.createTable(db);
        await OrderProductsTable.createTable(db);
        await OrderItemsTable.createTable(db);
        await InvoicesTable.createTable(db);
        await InvoiceProductsTable.createTable(db);
        await PaymentsTable.createTable(db);
        await SecurityQuestionsTable.createTable(db);
        await ProductFlagsView.createView(db);
        // You can also add any additional migration logic here if needed
        // For example, if you want to migrate data from old tables to new tables, you can do it here
      },
      onUpgrade: (db, _, __) async {
        // Drop all tables
        await CategoriesTable.dropTable(db);
        await ExpenseTypesTable.dropTable(db);
        await PaymentMethodsTable.dropTable(db);
        await UsersTable.dropTable(db);
        await UserLogsTable.dropTable(db);
        await ProductsTable.dropTable(db);
        await UnitsTable.dropTable(db);
        await OrdersTable.dropTable(db);
        await OrderProductsTable.dropTable(db);
        await OrderItemsTable.dropTable(db);
        await InvoicesTable.dropTable(db);
        await InvoiceProductsTable.dropTable(db);
        await PaymentsTable.dropTable(db);
        await SecurityQuestionsTable.dropTable(db);
        await ProductFlagsView.dropView(db);
        // Recreate all tables
        await CategoriesTable.createTable(db);
        await ExpenseTypesTable.createTable(db);
        await PaymentMethodsTable.createTable(db);
        await UsersTable.createTable(db);
        await UserLogsTable.createTable(db);
        await ProductsTable.createTable(db);
        await UnitsTable.createTable(db);
        await OrdersTable.createTable(db);
        await OrderProductsTable.createTable(db);
        await OrderItemsTable.createTable(db);
        await InvoicesTable.createTable(db);
        await InvoiceProductsTable.createTable(db);
        await PaymentsTable.createTable(db);
        await SecurityQuestionsTable.createTable(db);
        await ProductFlagsView.createView(db);
        // You can also add any additional migration logic here if needed
        // For example, if you want to migrate data from old tables to new tables, you can do it here
      },
      onOpen: (db) async {
        /// Regardless of the database version, we reset the login status for all users.

        /// Ensures that the state is usable for the server isolate.
        await UsersTable.createTable(db);

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
            UserLog.logout(
              user: User.fromMap(userMap),
              eventTime: lastHeartbeat,
            ),
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
            if (isDebugMode) {
              printBoxed('Unknown batch operation method: $method with params: $params');
            }
        }
        break;

      default:
        if (isDebugMode) {
          printBoxed('Unknown batch operation format: $op');
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
