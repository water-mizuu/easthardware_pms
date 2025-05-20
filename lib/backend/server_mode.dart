import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:async_queue/async_queue.dart';
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
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:easthardware_pms/utils/server_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart';
import "package:shelf/shelf_io.dart" as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const otherIsolate = Object();
// Database instance cache
Database? _databaseInstance;

@otherIsolate
Future<Database> _getDatabase() async {
  assert(RootIsolateToken.instance == null,
      "This should be called on another isolate.");
  if (_databaseInstance == null) {
    // Initialize the database - this would typically be your actual database initialization
    // For example:
    if (Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = join(await getDatabasesPath(), 'server_return database.db');
    _databaseInstance =
        await openDatabase(path, version: 2, onCreate: (db, version) {
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
                  {
                    'where': String? where,
                    'whereArgs': List<Object?>? whereArgs
                  }
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
              print(
                  'Unknown batch operation method: $method with params: $params');
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
    return batch.commit(
        exclusive: exclusive,
        noResult: noResult,
        continueOnError: continueOnError);
  } else {
    return batch.apply(noResult: noResult, continueOnError: continueOnError);
  }
}

@otherIsolate
Future<dynamic> _handleDbMethod(String method, List<Object?> arguments) async {
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
        return isolateDatabase.delete(table,
            where: where, whereArgs: whereArgs);
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
            {
              'nullColumnHack': String? nullColumnHack,
              'conflictAlgorithm': int? conflictAlgorithm
            }
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
      if (arguments
          case [
            String sql,
            List<Object?>? args,
            {'bufferSize': int? bufferSize}
          ]) {
        return isolateDatabase.rawQueryCursor(sql, args,
            bufferSize: bufferSize);
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
            {
              'noResult': bool? noResult,
              'continueOnError': bool? continueOnError
            }
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

  throw UnsupportedError(
      'Unsupported database method: $method or invalid arguments: $arguments');
}

/// Hosts a shelf server on the given port.
/// Returns a tuple containing the server channel, the port, and a function to close the server.
/// - The server channel is used to communicate with the server.
/// - The port is the port on which the server is hosted.
/// - The close function is used to stop the server.
Future<(ServerChannel, int, Future<void> Function() close)> hostShelfServer(
    int port) async {
  final receivePort = ReceivePort().hostListener();
  final isolate = await Isolate.spawn(_spawnIsolate, (
    RootIsolateToken.instance!,
    receivePort.sendPort,
    port,
  ));
  isolate.addErrorListener(receivePort.sendPort);
  final sendPort = await receivePort.next<SendPort>();
  final receivedServerPort = await receivePort.next();
  if (receivedServerPort case (Object error, StackTrace _)) {
    throw error;
  }

  assert(receivedServerPort == port,
      "The server port is not the same as the one provided.");

  final channel = ServerChannel(receivePort, sendPort);

  return (
    channel,
    port,
    () async {
      final received = await channel.invoke("stop");

      switch (received) {
        case 0:
          if (kDebugMode) {
            print("Isolate stopped successfully.");
          }
          receivePort.close();
          break;
        case _:
          if (kDebugMode) {
            print("Failed to stop the isolate.");
          }
          break;
      }
    }
  );
}

late AsyncQueue _asyncQueue;

/// Spawns an isolate to handle database operations and WebSocket connections.
///   This isolate will handle incoming messages and perform database operations
///   as needed.
@otherIsolate
Future<void> _spawnIsolate((RootIsolateToken, SendPort, int) payload) async {
  // Unpack the arguments
  final (token, sendPort, givenPort) = payload;

  // Ensure messenger to allow communication.
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  _asyncQueue = AsyncQueue.autoStart();

  // Create the receive port and send it to the main isolate.
  final receivePort = ReceivePort().hostListener();
  sendPort.send(receivePort.sendPort);

  // Start a shelf server on the given port.
  final (server, error) = await _shelfInitiate(givenPort, _handleConnection);
  if (error != null) {
    sendPort.send(error);
    return;
  }

  // Send the server port back to the main isolate.
  //  The main isolate compares the port to the one provided.
  sendPort.send(server!.port);

  var isRunning = true;
  while (isRunning) {
    final message = await receivePort.next();

    if (message case ["stop", ...]) {
      // End the while loop
      isRunning = false;

      // Close the shelf server
      await server.close();

      // Clear the async queue
      _asyncQueue.clear();

      // Close this isolate's receive port.
      receivePort.close();

      if (kDebugMode) {
        print("Isolate stopped.");
      }

      /// Success code 0.
      sendPort.send(0);
    } else if (message case ["db", [String method, List<Object?> arguments]]) {
      // Handle each db method call.
      final result = await _handleDbMethod(method, arguments);
      sendPort.send(result);
    } else {
      if (kDebugMode) {
        print("Received unexpected message: $message");
      }
    }
  }

  if (kDebugMode) {
    print("Isolate finished.");
  }
}

/// Initializes the shelf server, returning the server instance and the port.
/// The port MAY need to be user modifiable.
///   There is no guarantee that the port will be the same as the one provided.
///    Otherwise, the port will be the same as the one provided.)
Future<(HttpServer?, Object?)> _shelfInitiate(
  int port,
  FutureOr<void> Function(WebSocketChannel channel, [String? subprotocol])
      onConnect,
) async {
  assert(RootIsolateToken.instance == null,
      "This function must be called from another isolate.");
  final network = NetworkInfo();

  final ip = await network.getWifiIP().then((p) => p!);
  final handler = webSocketHandler(onConnect);

  try {
    final server = await shelf_io.serve(handler, ip, port);
    final hostedPort = server.port;

    if (kDebugMode) {
      print("Serving at $ip:$hostedPort");
    }

    return (server, null);
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print("Failed to start server: $e");
    }
    return (null, (e, stackTrace));
  }
}

extension ServerChannelExtension on WebSocketChannel {
  ServerChannel toServerChannel({FutureOr<void> Function()? close}) {
    final receivePort = ReceivePort().hostListener();
    final sendPort = receivePort.sendPort;

    final internalReceivePort = ReceivePort()
      ..listen((object) {
        var result = jsonEncode(object);
        if (kDebugMode) {
          // print(["Sending to client", result]);
        }

        sink.add(result);
      });
    final internalSendPort = internalReceivePort.sendPort;

    stream.listen((m) {
      var result = jsonDecode(m);
      if (kDebugMode) {
        // print(["Received from client", result]);
      }

      sendPort.send(result);
    }, onDone: () async {
      await close?.call();
      internalReceivePort.close();
      receivePort.close();

      if (kDebugMode) {
        print("Closed connection to a client.");
      }
    });

    return ServerChannel(receivePort, internalSendPort);
  }
}

FutureOr<void> _handleConnection(
  WebSocketChannel channel, [
  String? subprotocol,
]) async {
  // Handle WebSocket connection

  var running = true;
  final serverChannel = channel.toServerChannel(close: () => running = false) //
    // Send a status code of 0 to indicate success.
    ..sendPort.send(0);

  do {
    /// Just keep running until the client disconnects.
    final result = await serverChannel.receivePort.next();

    if (result case ["db", [String method, List<Object?> arguments]]) {
      // Handle each db method call.
      final result = await _handleDbMethod(method, arguments);
      serverChannel.sendPort.send(result);
    } else {
      if (kDebugMode) {
        print("Received unexpected message: $result");
      }
    }
  } while (running);
}
