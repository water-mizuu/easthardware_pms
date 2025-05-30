import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async_queue/async_queue.dart';
import 'package:easthardware_pms/domain/backend/classes/secure_connection.dart';
import 'package:easthardware_pms/domain/backend/extensions/to_message_channel.dart';
import 'package:easthardware_pms/domain/backend/server_database.dart';
import 'package:easthardware_pms/domain/backend/utils/isolate_indicator.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:easthardware_pms/utils/try_future.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import "package:shelf/shelf_io.dart" as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

late MessageChannel mainChannel;
late List<(WebSocketChannel, MessageChannel)> _clientChannels;
late AsyncQueue _handleConnectionQueue;
late AsyncQueue _dbMethodQueue;

/// Spawns an isolate to handle database operations and WebSocket connections.
///   This isolate will handle incoming messages and perform database operations
///   as needed.
Future<void> spawnWebSocketIsolate((RootIsolateToken, NamedSendPort) payload) async {
  assertChildIsolate();

  // Unpack the arguments
  final (token, sendPort) = payload;

  // Ensure messenger to allow communication.
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  _clientChannels = <(WebSocketChannel, MessageChannel)>[];
  _handleConnectionQueue = AsyncQueue.autoStart();
  _dbMethodQueue = AsyncQueue.autoStart();

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

  // Send the server port back to the main isolate.
  //  The main isolate compares the port to the one provided.
  sendPort.send("setup", server!.port);

  /// Listen for messages from the main isolate.
  /// This method handles closing the server and the objects created in this isolate.
  Future<void> closeIsolate(String name) async {
    // Close the shelf server
    await server.close(force: true);

    // Close all WebSocket connections
    for (final (webSocket, messageChannel) in _clientChannels.toList()) {
      await webSocket.sink.close();

      /// Ensure that the message channel for this WebSocket is closed to avoid memory leaks.
      assert(messageChannel.receivePort.isClosed);
    }

    // Clear the async queues
    _handleConnectionQueue.clear();
    _dbMethodQueue.clear();

    // Close this isolate's receive port.
    receivePort.close();
    if (kDebugMode) {
      print("Isolate stopped.");
    }

    /// Success code 0.
    sendPort.send(name, 0);
  }

  /// @MAIN2WS:invocation
  mainChannel.listenFrom("invocation", (message) {
    if (kDebugMode) {
      printBoxed(message, "MAIN2WS:invocation");
    }

    if (message case [final String returnName, final Object args]) {
      switch (args) {
        case ["stop", _]:
          closeIsolate(returnName);
          break;
        case ["db", [final String method, final List<Object?> arguments]]:
          _dbMethodQueue.addJob((_) async {
            // Handle each db method call.
            final output = await serverHandleDatabaseMethod(method, arguments);
            if (kDebugMode) {
              print("Database method $method called with arguments: $arguments");
            }

            final DatabaseMethodResult(:result, :hasChanged) = output;

            // Send the result back to the client.
            sendPort.send(returnName, result);
            if (hasChanged) {
              _notifyEveryoneAboutDatabaseChange(from: null, isServerUpdated: false);
            }
          });
          break;
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
    () => _clientChannels.remove((webSocketChannel, messageChannel)),
  )

    // Send a status code of 0 to indicate success.
    ..sendPort.send("status", 0);

  /// @CLIENT2WS:invocation
  messageChannel.listenFrom("invocation", (object) {
    if (kDebugMode) {
      printBoxed(object, "CLIENT2WS:invocation");
    }

    final [name as String, message] = object as List<Object?>;

    switch (message) {
      case ["db", [final String method, final List<Object?> arguments]]:
        _dbMethodQueue.addJob((_) async {
          // Handle each db method call.
          final output = await serverHandleDatabaseMethod(method, arguments);
          if (kDebugMode) {
            print("Database method $method called with arguments: $arguments");
          }

          final DatabaseMethodResult(:result, :hasChanged) = output;

          // Send the result back to the client.
          messageChannel.sendPort.send(name, result);

          if (hasChanged) {
            _notifyEveryoneAboutDatabaseChange(from: webSocketChannel, isServerUpdated: true);
          }
        });
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

  _clientChannels.add((webSocketChannel, messageChannel));
}

/// This sends out a notification to all connected clients about a database change.
/// This also sends the notification to the server as necessary.
Future<void> _notifyEveryoneAboutDatabaseChange({
  required WebSocketChannel? from,
  required bool isServerUpdated,
}) async {
  assertChildIsolate();
  if (isServerUpdated) {
    mainChannel.sendPort.send("main", ["didUpdate", DateTime.now().millisecondsSinceEpoch]);
  }

  for (final (client, channel) in _clientChannels) {
    if (client != from) {
      // Notify all other clients about the database change.
      channel.sendPort.send("client", ["didUpdate", DateTime.now().millisecondsSinceEpoch]);
    }
  }
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
