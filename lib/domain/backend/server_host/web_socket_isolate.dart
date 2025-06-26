import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async_queue/async_queue.dart';
import 'package:easthardware_pms/data/database/dao/user_logs_dao.dart';
import 'package:easthardware_pms/data/database/dao/users_dao.dart';
import 'package:easthardware_pms/domain/backend/classes/secure_connection.dart';
import 'package:easthardware_pms/domain/backend/extension_types/log_command.dart';
import 'package:easthardware_pms/domain/backend/extensions/to_message_channel.dart';
import 'package:easthardware_pms/domain/backend/server_database.dart';
import 'package:easthardware_pms/domain/backend/utils/isolate_indicator.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/models/user_log.dart';
import 'package:easthardware_pms/main.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/duration.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:easthardware_pms/utils/try_future.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import "package:shelf/shelf_io.dart" as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

late final SharedPreferencesAsync _sharedPreferencesAsync;
late final int? _savedHeartbeat;
late int? _userId;
late MessageChannel mainChannel;
late List<(WebSocketChannel, MessageChannel, int? userId)> _clientChannels;
late Timer _heartbeatTimer;
late AsyncQueue _handleConnectionQueue;

/// Spawns an isolate to handle database operations and WebSocket connections.
///   This isolate will handle incoming messages and perform database operations
///   as needed.
Future<void> spawnWebSocketIsolate((RootIsolateToken, NamedSendPort) payload) async {
  assertChildIsolate();

  // Unpack the arguments
  final (token, sendPort) = payload;

  // Ensure messenger to allow communication.
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  _sharedPreferencesAsync = SharedPreferencesAsync();

  _savedHeartbeat = await _sharedPreferencesAsync.getInt("heartbeat");
  if (kDebugMode) {
    printBoxed("Saved heartbeat: $_savedHeartbeat", "Spawn WebSocket Isolate");
  }

  _clientChannels = <(WebSocketChannel, MessageChannel, int?)>[];
  _handleConnectionQueue = AsyncQueue.autoStart();

  // Create the receive port and send it to the main isolate.
  final receivePort = ReceivePort().hostListener();
  sendPort.send("setup", receivePort.sendPort);

  mainChannel = MessageChannel(receivePort, sendPort);

  // Start a shelf server on any port.
  final (server, error) = await _shelfWebSocketInitiate(0).tryCatch();
  if (error != null) {
    sendPort.send("setup", error);
    return;
  } else if (server != null) {
    sendPort.send("setup", 0);
  }

  // Set up the heartbeat timer. This will be used to detect unexpected crashes of the isolate.
  await _sharedPreferencesAsync.setInt("heartbeat", DateTime.now().millisecondsSinceEpoch);
  _heartbeatTimer = Timer.periodic(15.seconds, (timer) async {
    await _sharedPreferencesAsync.setInt("heartbeat", DateTime.now().millisecondsSinceEpoch);
  });

  // Send the server port back to the main isolate.
  //  The main isolate compares the port to the one provided.
  sendPort.send("setup", server!.port);

  /// Listen for messages from the main isolate.
  /// This method handles closing the server and the objects created in this isolate.
  Future<void> closeIsolate(String name) async {
    // Close the shelf server
    await server.close(force: true);

    // Close the heartbeat timer, invalidate the heartbeat.
    _heartbeatTimer.cancel();
    await SharedPreferencesAsync().remove("heartbeat");

    // Close all WebSocket connections
    for (final (webSocket, messageChannel, userId) in _clientChannels.toList()) {
      await webSocket.sink.close();

      if (userId != null) {
        // Notify the main isolate about the user logout.
        await _logoutClientForcefully(userId);
      }

      /// Ensure that the message channel for this WebSocket is closed to avoid memory leaks.
      assert(messageChannel.receivePort.isClosed);
    }

    // Clear the async queues
    _handleConnectionQueue.clear();

    // Close this isolate's receive port.
    receivePort.close();
    printBoxed("Isolate stopped.", "WEBSOCKET SERVER");

    /// Success code 0.
    sendPort.send(name, 0);
  }

  /// @MAIN2WS:invocation
  mainChannel.listenFrom("invocation", (message) async {
    if (kDebugMode) {
      if (printInvocationMessages) {
        printBoxed(message, "MAIN2WS:invocation");
      }
    }

    if (message case [final String name, final Object args]) {
      switch (args) {
        case ["stop", _]:
          await closeIsolate(name);
          break;
        case ["resetDb", _]:
          // // Restart the database connection.
          await resetDatabase();
          sendPort.send(name, 0);
          break;
        case ["db", [final String method, final List<Object?> arguments]]:
          // Handle each db method call.
          final hasChanged = await _handleDbMessage(method, arguments, sendPort, name);

          /// If the method was not successfully handled, ignore the rest of this body.
          if (hasChanged == null) break;
          if (hasChanged) {
            _notifyEveryoneAboutDatabaseChange(from: null, isServerUpdated: false);
          }

          /// Hook onto the database update that signifies that the user has logged in.
          if (method == "update") {
            await _hookOntoUpdate(arguments);
          }
          break;
        case ["create_backup", [final String key]]:
          // Handle backup requests.
          final result = await createBackup(key);
          __notifyEveryoneAboutDatabaseChangeInstantly(from: null, isServerUpdated: true);

          sendPort.send(name, result);
          break;
        case ["restore_backup", [final String path, final String key]]:
          // Handle restore requests.
          try {
            final (_) = await restoreBackup(path, key);
            __notifyEveryoneAboutDatabaseChangeInstantly(from: null, isServerUpdated: true);

            sendPort.send(name, true);
          } catch (e) {
            sendPort.send(name, ["error", "Failed to restore backup: $e"]);
          }
          break;
        case ["delete_backup", [final String path]]:
          // Handle delete backup requests.
          try {
            final (_) = await deleteBackup(path);
            __notifyEveryoneAboutDatabaseChangeInstantly(from: null, isServerUpdated: true);

            sendPort.send(name, true);
          } catch (e) {
            sendPort.send(name, ["error", "Failed to delete backup: $e"]);
          }
        case ["get_database_size", _]:
          // Handle get database size requests.
          final size = await getDatabaseSize();
          sendPort.send(name, size);
          break;
        case ["load_backups", _]:
          final result = await readBackups();

          sendPort.send(name, result);
          break;
        case _:
          printBoxed("Unknown message type: $args", "MAIN2WS:invocation");
          sendPort.send(name, [
            "error",
            "Unknown message type: $args",
            StackTrace.current.toString(),
          ]);
      }
    } else {
      if (kDebugMode) {
        print("Received unexpected message: $message");
      }
    }
  });
}

/// Initializes the shelf server, returning the server instance and the port.
/// The port MAY need to be user modifiable.
///   There is no guarantee that the port will be the same as the one provided.
///    Otherwise, the port will be the same as the one provided.)
Future<HttpServer> _shelfWebSocketInitiate(int port) async {
  assertChildIsolate();
  final network = NetworkInfo();

  final ip = await network.getWifiIP().then((p) => p!);
  final handler = const Pipeline().addMiddleware(logRequests()).addHandler((request) async {
    /// Get the key stored in the query parameters.
    final queryParams = request.url.queryParameters;
    final sessionKeyRaw = queryParams['key'];
    if (sessionKeyRaw == null) return Response.forbidden("Missing session key");

    /// If it is the wrong type, return a forbidden response.
    final sessionKey = int.tryParse(sessionKeyRaw);
    if (sessionKey == null) return Response.forbidden("Invalid session key");

    /// Now, we ask the other isolate for an existing connection.
    final (connection, error) = await _requestConnection(sessionKey).tryCatch();
    if (error != null) return Response.internalServerError(body: "Error requesting connection");

    return webSocketHandler((c, [sp]) {
      _handleConnectionQueue.addJob((_) => _handleConnection(connection!, c));
    }, pingInterval: const Duration(seconds: 3))(request);
  });

  final server = await shelf_io.serve(handler, ip, port);
  final hostedPort = server.port;

  if (kDebugMode) {
    print("Serving at $ip:$hostedPort");
  }

  return server;
}

/// Handles the WebSocket connection.
/// A webSocket connection is established whenever a client connects to the server.
Future<void> _handleConnection(
  SecureConnection connection,
  WebSocketChannel webSocketChannel,
) async {
  assertChildIsolate();

  late final MessageChannel messageChannel;
  messageChannel = webSocketChannel.toEncryptedMessageChannel(
    connection.encryptionKey,
    () {
      final index = _clientChannels //
          .indexWhere((c) => c.$1 == webSocketChannel && c.$2 == messageChannel);

      assert(index != -1, "The channel should be in the list of client channels.");
      if (index == -1) return;

      /// If the channel had an account associated with it,
      ///   log out the user.
      final (_, _, userId) = _clientChannels[index];
      if (userId != null) {
        _logoutClientForcefully(userId);
      }

      /// Remove the channel from the list of client channels.
      _clientChannels.removeAt(index);
    },
  )..sendPort.send("status", 0);

  /// @CLIENT2WS:invocation
  messageChannel.listenFrom("invocation", (object) async {
    if (kDebugMode) {
      if (printInvocationMessages) {
        printBoxed(object, "CLIENT2WS:invocation");
      }
    }

    final [name as String, message] = object as List<Object?>;
    final sendPort = messageChannel.sendPort;

    switch (message) {
      case ["resetDb", _]:
        await resetDatabase();
        break;
      case ["db", [final String method, final List<Object?> arguments]]:
        // Handle each db method call.
        final hasChanged = await _handleDbMessage(method, arguments, sendPort, name);

        /// If the method was not successfully handled, ignore the rest of this body.
        if (hasChanged == null) break;
        if (hasChanged) {
          _notifyEveryoneAboutDatabaseChange(from: webSocketChannel, isServerUpdated: true);
        }

        /// Hook onto the database update that signifies that the user has logged in.
        if (method == "update") {
          await _hookOntoUpdate(arguments, (webSocketChannel, messageChannel));
        }

        break;
      case ["create_backup", [final String key]]:
        // Handle backup requests.
        final result = await createBackup(key);
        __notifyEveryoneAboutDatabaseChangeInstantly(from: null, isServerUpdated: true);

        sendPort.send(name, result);
        break;
      case ["restore_backup", [final String path, final String key]]:
        // Handle restore requests.
        try {
          final (_) = await restoreBackup(path, key);
          __notifyEveryoneAboutDatabaseChangeInstantly(from: null, isServerUpdated: true);

          sendPort.send(name, true);
        } catch (e) {
          sendPort.send(name, ["error", "Failed to restore backup: $e"]);
        }
        break;
      case ["delete_backup", [final String path]]:
        // Handle delete backup requests.
        try {
          final (_) = await deleteBackup(path);
          __notifyEveryoneAboutDatabaseChangeInstantly(from: null, isServerUpdated: true);

          sendPort.send(name, true);
        } catch (e) {
          sendPort.send(name, ["error", "Failed to delete backup: $e"]);
        }
      case ["get_database_size", _]:
        // Handle get database size requests.
        final size = await getDatabaseSize();

        sendPort.send(name, size);
        break;
      case ["load_backups", _]:
        final result = await readBackups();

        sendPort.send(name, result);
        break;
      case _:
        if (kDebugMode) {
          print("Received unexpected message: $message");
        }
        break;
    }
  });

  if (kDebugMode) {
    print("New connection established. Current connections: ${_clientChannels.length + 1}");
  }

  _clientChannels.add((webSocketChannel, messageChannel, null));
}

Future<bool?> _handleDbMessage(
  String method,
  List<Object?> arguments,
  NamedSendPort sendPort,
  String name,
) async {
  assertChildIsolate();
  // printBoxed(
  //   "Handling database method: $method with arguments: $arguments",
  //   "WebSocket Isolate",
  // );

  final (output, error) = await serverHandleDatabaseMethod(method, arguments, _savedHeartbeat) //
      .tryCatch();

  if (error case (final Object error, final StackTrace stackTrace)) {
    sendPort.send(name, ["error", error.toString(), stackTrace.toString()]);
    return null;
  }
  if (output == null) {
    sendPort.send(name, ["error", "Output is null", StackTrace.current.toString()]);
    return null;
  }

  final (result, hasChanged) = output.record;

  // Send the result back to the client.
  sendPort.send(name, result);

  return hasChanged;
}

/// This timer is used to debounce the notifications of consequent
///   database changes to the clients.
Timer? _notifyTimer;
WebSocketChannel? _fromChannel;
bool _isServerUpdated = false;

/// This is the duration after which the notification timer will send out
/// notifications to the clients about the database change.
const Duration notifyTimerDuration = Duration(seconds: 1);

/// This sends out a notification to all connected clients about a database change.
/// This also sends the notification to the server as necessary.
void _notifyEveryoneAboutDatabaseChange({
  required WebSocketChannel? from,
  required bool isServerUpdated,
}) {
  assertChildIsolate();

  _notifyTimer?.cancel();

  /// If someone requested to notify everyone about a database change,
  ///   and someone else requests it too, and those two requests are from different
  ///   clients, then we want to basically notify everyone (including the two clients).
  _fromChannel = (_fromChannel != null && from != _fromChannel) ? null : _fromChannel;

  /// In the same way, if the server was not requested to be updated, and an existing
  ///   request was made, we want to keep the server updated.
  _isServerUpdated = _isServerUpdated || isServerUpdated;

  _notifyTimer = Timer(notifyTimerDuration, () {
    __notifyEveryoneAboutDatabaseChangeInstantly(
      isServerUpdated: _isServerUpdated,
      from: _fromChannel,
    );

    _fromChannel = null;
    _isServerUpdated = false;
  });
}

void __notifyEveryoneAboutDatabaseChangeInstantly({
  required WebSocketChannel? from,
  required bool isServerUpdated,
}) {
  assertChildIsolate();

  if (isServerUpdated && mainChannel.isOpen) {
    mainChannel.sendPort.send("main", ["didUpdate", DateTime.now().millisecondsSinceEpoch]);
  }

  for (final (client, channel, _) in _clientChannels) {
    if (client != from && channel.isOpen) {
      // Notify all other clients about the database change.
      channel.sendPort.send("client", ["didUpdate", DateTime.now().millisecondsSinceEpoch]);
    }
  }
}

/// This method hooks onto the database update that signifies that the user has logged in.
/// We need to ensure that this matches the signature of the update method in the database helper.
Future<void> _hookOntoUpdate(
  List<Object?> arguments, [
  (WebSocketChannel, MessageChannel)? clientChannel,
]) async {
  late final index = _clientChannels.indexWhere((c) => (c.$1, c.$2) == clientChannel);

  /// MANUAL LOGIN.
  if (arguments
      case [
        "users",
        {"login_status": 1},
        {"where": "id = ?", "whereArgs": [final int userId]},
      ]) {
    if (clientChannel case (final webSocketChannel, final messageChannel) when index >= 0) {
      _clientChannels[index] = (webSocketChannel, messageChannel, userId);

      if (kDebugMode) {
        print("User with ID $userId logged in from an existing client.");
      }

      final db = await getWebSocketDatabaseHelper(_savedHeartbeat);
      final usersDao = UsersDao(db);
      final user = await usersDao.getUserById(userId);
      if (user == null) {
        if (kDebugMode) {
          print("User with ID $userId not found in the database.");
        }
        return;
      }

      await _logToMain(LogCommand.userLoggedIn, user);
    } else {
      /// We assume that the user logged in from the server.
      _userId = userId;

      if (kDebugMode) {
        print("User with ID $userId logged in from a new client.");
      }
    }
    return;
  }

  /// MANUAL LOGOUT.
  ///   If we detect a manual logout (either the client or the server pressed the logout button),
  ///   we want to let everyone know about it.
  if (arguments
      case [
        "users",
        {"login_status": 0},
        {"where": "id = ?", "whereArgs": [final int userId]},
      ]) {
    if (clientChannel case (final webSocketChannel, final messageChannel) when index >= 0) {
      _clientChannels[index] = (webSocketChannel, messageChannel, null);

      final db = await getWebSocketDatabaseHelper(_savedHeartbeat);
      final usersDao = UsersDao(db);
      final user = await usersDao.getUserById(userId);
      if (user == null) {
        if (kDebugMode) {
          print("User with ID $userId not found in the database.");
        }
        return;
      }

      await _logToMain(LogCommand.userLoggedOut, user);
    } else {
      assert(_userId == userId, "User ID should match the one in the arguments.");
      _userId = null;
    }

    return;
  }
}

/// Logs to the user in the main isolate that a user has logged out.
Future<void> _logToMain(LogCommand command, User user) async {
  assertChildIsolate();

  await mainChannel.invokeMain(command as String, [user]);
}

Future<SecureConnection> _requestConnection(int sessionKey) async {
  assertChildIsolate();

  final connection = await mainChannel.invokeNamed("main", "requestConnection", [sessionKey]);
  if (connection case SecureConnection()) {
    return connection;
  } else {
    throw Exception("Invalid connection response: $connection");
  }
}

Future<void> _logoutClientForcefully(int userId) async {
  assertChildIsolate();

  final dbHelper = await getWebSocketDatabaseHelper(_savedHeartbeat);

  {
    /// We want to set the user as inactive in the database.
    final userListDao = UsersDao(dbHelper);

    await userListDao.setUserAsInactive(userId);
  }

  {
    /// We want to log this inactivity in the server database.
    final userListDao = UsersDao(dbHelper);
    final userLogsDao = UserLogsDao(dbHelper);

    final user = await userListDao.getUserById(userId);
    if (user == null) {
      if (kDebugMode) {
        print("User with ID $userId not found in the database.");
      }
      return;
    }

    await userLogsDao.insertUserLog(UserLog.logout(user: user));
  }

  _notifyEveryoneAboutDatabaseChange(from: null, isServerUpdated: true);
}
