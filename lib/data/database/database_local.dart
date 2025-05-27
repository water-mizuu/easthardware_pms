import 'dart:io';

import "package:path/path.dart";
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseLocal implements Database {
  DatabaseLocal();

  Database? _instance;

  Future<void> initialize({
    OnDatabaseConfigureFn? onConfigure,
    OnDatabaseCreateFn? onCreate,
    OnDatabaseVersionChangeFn? onUpgrade,
    OnDatabaseVersionChangeFn? onDowngrade,
    OnDatabaseOpenFn? onOpen,
  }) async {
    if (Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final path = join(await getDatabasesPath(), 'app_database.db');

      _instance = await openDatabase(
        path,
        version: 1,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
        onDowngrade: onDowngrade,
        onOpen: onOpen,
      );
    }

    throw UnsupportedError(
      "Creating database is only supported on Windows / macOS",
    );
  }

  @override
  Batch batch() => _instance!.batch();

  @override
  Future<void> close() => _instance!.close();

  @override
  Database get database => _instance!;

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      _instance!.delete(table, where: where, whereArgs: whereArgs);

  @override
  Future<T> devInvokeMethod<T>(String method, [Object? arguments]) =>
      // ignore: deprecated_member_use
      _instance!.devInvokeMethod<T>(method, arguments);

  @override
  Future<T> devInvokeSqlMethod<T>(String method, String sql, [List<Object?>? arguments]) =>
      // ignore: deprecated_member_use
      _instance!.devInvokeSqlMethod<T>(method, sql, arguments);

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) =>
      _instance!.execute(sql, arguments);

  @override
  Future<int> insert(String table, Map<String, Object?> values,
          {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) =>
      _instance!.insert(table, values,
          nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);

  @override
  bool get isOpen => _instance!.isOpen;

  @override
  String get path => _instance!.path;

  @override
  Future<List<Map<String, Object?>>> query(String table,
          {bool? distinct,
          List<String>? columns,
          String? where,
          List<Object?>? whereArgs,
          String? groupBy,
          String? having,
          String? orderBy,
          int? limit,
          int? offset}) =>
      _instance!.query(table,
          distinct: distinct,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset);

  @override
  Future<QueryCursor> queryCursor(String table,
          {bool? distinct,
          List<String>? columns,
          String? where,
          List<Object?>? whereArgs,
          String? groupBy,
          String? having,
          String? orderBy,
          int? limit,
          int? offset,
          int? bufferSize}) =>
      _instance!.queryCursor(table,
          distinct: distinct,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          groupBy: groupBy,
          having: having,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
          bufferSize: bufferSize);

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) =>
      _instance!.rawDelete(sql, arguments);

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) =>
      _instance!.rawInsert(sql, arguments);

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) =>
      _instance!.rawQuery(sql, arguments);

  @override
  Future<QueryCursor> rawQueryCursor(String sql, List<Object?>? arguments, {int? bufferSize}) =>
      _instance!.rawQueryCursor(sql, arguments, bufferSize: bufferSize);

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) =>
      _instance!.rawUpdate(sql, arguments);

  @override
  Future<T> readTransaction<T>(Future<T> Function(Transaction txn) action) =>
      _instance!.readTransaction<T>(action);

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) =>
      _instance!.transaction<T>(action, exclusive: exclusive);

  @override
  Future<int> update(String table, Map<String, Object?> values,
          {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) =>
      _instance!.update(table, values,
          where: where, whereArgs: whereArgs, conflictAlgorithm: conflictAlgorithm);
}
