import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Represents a database server connection.
///  Specifically, the database must be on another isolate
///  which supports invoking methods on the database.
class Server {
  const Server(this._channel);
  final MessageChannel? _channel;

  bool get isOpen => _channel != null && !(_channel!.receivePort.isClosed);

  Future<dynamic> invokeDatabaseMethod(String method, List<Object?> arguments) async {
    final channel = _channel;
    if (channel == null) {
      throw StateError("Server channel is not initialized.");
    }

    return await channel.invoke("db", [method, arguments]);
  }

  Future<dynamic> invokeMethod(String method, List<Object?> arguments) async {
    final channel = _channel;
    if (channel == null) {
      throw StateError("Server channel is not initialized.");
    }

    return await channel.invoke(method, arguments);
  }
}

/// This class is a proxy for the server class.
///   It implements the Database interface and delegates all calls to the server class.
///   This allows us to use the same interface for both the server and client classes.
class DatabaseServerProxy implements Database {
  DatabaseServerProxy(this._server);

  final Server _server;

  @override
  Batch batch() => ServerBatch(_server);

  @override
  Database get database => this;

  @override
  bool get isOpen => _server.isOpen;

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) {
    return _server.invokeDatabaseMethod('delete', [
      table,
      {'where': where, 'whereArgs': whereArgs}
    ]).cast<int>();
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) {
    return _server.invokeDatabaseMethod('execute', [sql, arguments]);
  }

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    return _server.invokeDatabaseMethod(
      'insert',
      [
        table,
        values,
        {'nullColumnHack': nullColumnHack, 'conflictAlgorithm': conflictAlgorithm?.index}
      ],
    ).cast<int>();
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final result = await _server.invokeDatabaseMethod(
      'query',
      [
        table,
        {
          'distinct': distinct,
          'columns': columns,
          'where': where,
          'whereArgs': whereArgs,
          'groupBy': groupBy,
          'having': having,
          'orderBy': orderBy,
          'limit': limit,
          'offset': offset
        }
      ],
    );

    return [
      for (final entry in result as List<dynamic>)
        (entry as Map<String, dynamic>).cast<String, Object?>()
    ];
  }

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) {
    return _server.invokeDatabaseMethod('rawDelete', [sql, arguments]).cast<int>();
  }

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) {
    return _server.invokeDatabaseMethod('rawInsert', [sql, arguments]).cast<int>();
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final result = await _server.invokeDatabaseMethod('rawQuery', [sql, arguments]);

    return [
      for (final entry in result as List<dynamic>)
        (entry as Map<String, dynamic>).cast<String, Object?>()
    ];
  }

  @override
  Future<int> rawUpdate(
    String sql, [
    List<Object?>? arguments,
  ]) {
    return _server.invokeDatabaseMethod('rawUpdate', [sql, arguments]).cast<int>();
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    return _server.invokeDatabaseMethod(
      'update',
      [
        table,
        values,
        {'where': where, 'whereArgs': whereArgs, 'conflictAlgorithm': conflictAlgorithm}
      ],
    ).cast<int>();
  }

  @override
  Future<void> close() async {
    if (kDebugMode) {
      print("Close called on proxy database.");
    }
  }

  @override
  Future<T> devInvokeMethod<T>(String method, [Object? arguments]) {
    throw UnsupportedError("The method 'devInvokeMethod' is not supported.");
  }

  @override
  Future<T> devInvokeSqlMethod<T>(String method, String sql, [List<Object?>? arguments]) {
    throw UnsupportedError("The method 'devInvokeSqlMethod' is not supported.");
  }

  @override
  String get path => throw UnsupportedError("Path is not supported in server proxy");

  @override
  Future<T> readTransaction<T>(Future<T> Function(Transaction txn) action) {
    throw UnsupportedError("Read transaction is not supported in server proxy");
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) {
    throw UnsupportedError("Transaction is not supported in server proxy");
  }

  @override
  Future<QueryCursor> queryCursor(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
    int? bufferSize,
  }) {
    // return _server.invokeDatabaseMethod(
    //   'queryCursor',
    //   [
    //     table,
    //     {
    //       'distinct': distinct,
    //       'columns': columns,
    //       'where': where,
    //       'whereArgs': whereArgs,
    //       'groupBy': groupBy,
    //       'having': having,
    //       'orderBy': orderBy,
    //       'limit': limit,
    //       'offset': offset,
    //       'bufferSize': bufferSize
    //     }
    //   ],
    // );
    throw UnsupportedError("queryCursor is not supported in server proxy");
  }

  @override
  Future<QueryCursor> rawQueryCursor(String sql, List<Object?>? arguments, {int? bufferSize}) {
    // return _server.invokeDatabaseMethod(
    //   'rawQueryCursor',
    //   [
    //     sql,
    //     arguments,
    //     {'bufferSize': bufferSize}
    //   ],
    // );
    throw UnsupportedError("rawQueryCursor is not supported in server proxy");
  }
}

///
/// A batch is used to perform multiple operation as a single atomic unit.
/// A Batch object can be acquired by calling [Database.batch]. It provides
/// methods for adding operation. None of the operation will be
/// executed (or visible locally) until commit() is called.
///
///
/// ```
/// batch = db.batch();
/// batch.insert('Test', {'name': 'item'});
/// batch.update('Test', {'name': 'new_item'}, where: 'name = ?', whereArgs: ['item']);
/// batch.delete('Test', where: 'name = ?', whereArgs: ['item']);
/// results = await batch.commit();
/// ```
class ServerBatch implements Batch {
  ServerBatch(this._server);

  final Server _server;
  final List<List<Object?>> _operations = [];

  /// Commits all of the operations in this batch as a single atomic unit
  /// The result is a list of the result of each operation in the same order
  /// if [noResult] is true, the result list is empty (i.e. the id inserted
  /// the count of item changed is not returned.
  ///
  /// The batch is stopped if any operation failed
  /// If [continueOnError] is true, all the operations in the batch are executed
  /// and the failure are ignored (i.e. the result for the given operation will
  /// be a DatabaseException)
  ///
  /// During [OpenDatabaseOptions.onCreate], [OpenDatabaseOptions.onUpgrade],
  /// [OpenDatabaseOptions.onDowngrade] (we are already in a transaction) or if
  /// the batch was created in a transaction it will only be commited when
  /// the transaction is commited ([exclusive] is not used then).
  ///
  /// Otherwise, sqflite will start a transaction to commit this batch. In rare
  /// cases where you don't need an atomic operation, or where you are manually
  /// managing the transaction without using sqflite APIs, you can also use
  /// [apply] to run statements in this batch without a transaction managed by
  /// sqflite.
  @override
  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) {
    return _server.invokeDatabaseMethod(
      'batch.commit',
      [
        _operations,
        {'exclusive': exclusive, 'noResult': noResult, 'continueOnError': continueOnError}
      ],
    ).cast<List<dynamic>>();
  }

  /// Runs all statements in this batch non-atomically.
  ///
  /// Unlike [commit], which starts a transaction to commit statements in this
  /// batch atomically, [apply] will simply run the statements without starting
  /// a transaction internally.
  ///
  /// This can be useful in the rare cases where you don't need a sqflite
  /// transaction, for instance because you are manually starting a transaction
  /// or because you simply don't need the batch to be applied atomically.
  ///
  /// In general, prefer [commit] to run batches over this method.
  @override
  Future<List<Object?>> apply({bool? noResult, bool? continueOnError}) {
    return _server.invokeDatabaseMethod(
      'batch.apply',
      [
        _operations,
        {'noResult': noResult, 'continueOnError': continueOnError}
      ],
    ).cast<List<dynamic>>();
  }

  /// See [Database.rawInsert]
  @override
  void rawInsert(String sql, [List<Object?>? arguments]) {
    _operations.add([
      'rawInsert',
      [sql, arguments]
    ]);
  }

  /// See [Database.insert]
  @override
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    _operations.add([
      'insert',
      [
        table,
        values,
        {'nullColumnHack': nullColumnHack, 'conflictAlgorithm': conflictAlgorithm?.index}
      ]
    ]);
  }

  /// See [Database.rawUpdate]
  @override
  void rawUpdate(String sql, [List<Object?>? arguments]) {
    _operations.add([
      'rawUpdate',
      [sql, arguments]
    ]);
  }

  /// See [Database.update]
  @override
  void update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    _operations.add([
      'update',
      [
        table,
        values,
        {
          'where': where,
          'whereArgs': whereArgs,
          'conflictAlgorithm': conflictAlgorithm?.index,
        }
      ]
    ]);
  }

  /// See [Database.rawDelete]
  @override
  void rawDelete(String sql, [List<Object?>? arguments]) {
    _operations.add([
      'rawDelete',
      [sql, arguments]
    ]);
  }

  /// See [Database.delete]
  @override
  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    _operations.add([
      'delete',
      [
        table,
        {'where': where, 'whereArgs': whereArgs}
      ]
    ]);
  }

  /// See [Database.execute];
  @override
  void execute(String sql, [List<Object?>? arguments]) {
    _operations.add([
      'execute',
      [sql, arguments]
    ]);
  }

  /// See [Database.query];
  @override
  void query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    _operations.add([
      'query',
      [
        table,
        {
          'distinct': distinct,
          'columns': columns,
          'where': where,
          'whereArgs': whereArgs,
          'groupBy': groupBy,
          'having': having,
          'orderBy': orderBy,
          'limit': limit,
          'offset': offset
        }
      ]
    ]);
  }

  /// See [Database.query];
  @override
  void rawQuery(String sql, [List<Object?>? arguments]) {
    _operations.add([
      'rawQuery',
      [sql, arguments]
    ]);
  }

  /// Current batch size
  @override
  int get length => _operations.length;
}

extension on Future {
  /// Cast the future to the given type
  Future<T> cast<T>() async {
    return await this as T;
  }
}
