/// This library contains the code which hosts a shelf server
///   through a background isolate.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async_queue/async_queue.dart';
import 'package:easthardware_pms/backend/extensions/to_message_channel.dart';
import 'package:easthardware_pms/backend/server_database.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import "package:shelf/shelf_io.dart" as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

late List<(WebSocketChannel, MessageChannel)> _clientChannels;
late AsyncQueue _handleConnectionQueue;
late AsyncQueue _dbMethodQueue;
late MessageChannel mainChannel;

/// Hosts a shelf server on the given port.
/// Returns a tuple containing the server channel, and a function to close the server.
/// - The server channel is used to communicate with the server.
/// - The close function is used to stop the server.
Future<(MessageChannel, Future<void> Function() close)> hostShelfServer(int port) async {
  /// Create a receive port to communicate with the isolate.
  final receivePort = ReceivePort().hostListener();

  /// Spawn an isolate which hosts the server.
  await Isolate.spawn(_spawnIsolate, (
    RootIsolateToken.instance!,
    receivePort.sendPort,
    port,
  ));

  /// The first message sent from the isolate is the [SendPort] of the isolate.
  final sendPort = await receivePort.next<NamedSendPort>("sendPort");

  /// Next, a status code or an error is sent from the isolate.
  final status = await receivePort.next<Object>("status");
  if (status case (final Object error, final StackTrace stackTrace)) {
    Error.throwWithStackTrace(error, stackTrace);
  }
  assert(status == 0, "The isolate should yield 0 after spawning properly.");

  final receivedServerPort = await receivePort.next<int>("port");
  assert(receivedServerPort == port, "The server port should be the same as the one provided.");

  /// When everything is correct, we can create a [MessageChannel] to communicate with the isolate.
  mainChannel = MessageChannel(receivePort, sendPort);

  /// We create a dispose function to stop the isolate.
  ///   This allows us to not expose the isolate itself to the user.
  Future<void> dispose() async {
    final status = await mainChannel.invoke("stop");
    switch (status) {
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

  return (mainChannel, dispose);
}

Stream<ServerEvent> postServerSetup(MessageChannel channel) async* {
  final receivePort = channel.receivePort;

  while (!receivePort.isClosed) {
    final message = await receivePort.next("main");

    switch (message) {
      case ["didUpdate", final int msSinceEpoch]:
        // Notify the UI that the server has been updated.
        final dateTime = DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
        if (kDebugMode) {
          print("Server updated at: $dateTime");
        }

        yield ServerDatabaseUpdated(lastUpdated: dateTime);
        break;
      case _:
        if (kDebugMode) {
          print("Received unexpected message: $message");
        }
        break;
    }
  }
}

/// Spawns an isolate to handle database operations and WebSocket connections.
///   This isolate will handle incoming messages and perform database operations
///   as needed.
Future<void> _spawnIsolate((RootIsolateToken, NamedSendPort, int) payload) async {
  // Unpack the arguments
  final (token, sendPort, givenPort) = payload;

  // Ensure messenger to allow communication.
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  _clientChannels = [];
  _handleConnectionQueue = AsyncQueue.autoStart();
  _dbMethodQueue = AsyncQueue.autoStart();

  // Create the receive port and send it to the main isolate.
  final receivePort = ReceivePort().hostListener();
  sendPort.send("sendPort", receivePort.sendPort);

  mainChannel = MessageChannel(receivePort, sendPort);

  // Start a shelf server on the given port.
  final (server, error) = await _shelfInitiate(givenPort);
  if (error != null) {
    sendPort.send("status", error);
    return;
  } else if (server != null) {
    sendPort.send("status", 0);
  }

  // Send the server port back to the main isolate.
  //  The main isolate compares the port to the one provided.
  sendPort.send("port", server!.port);

  /// Listen for messages from the main isolate.
  unawaited(() async {
    var run = true;

    /// This method handles closing the server and the objects created in this isolate.
    Future<void> closeIsolate(String name) async {
      run = false;

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

    /// This part handles messages received from the main isolate.
    /// It listens for messages and performs actions based on the message type.
    while (run) {
      final message = await receivePort.next("invocation");
      if (message case [final String returnName, final Object args]) {
        switch (args) {
          case ["stop", ...]:
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
    }
  }());
}

/// Initializes the shelf server, returning the server instance and the port.
/// The port MAY need to be user modifiable.
///   There is no guarantee that the port will be the same as the one provided.
///    Otherwise, the port will be the same as the one provided.)
Future<(HttpServer?, Object?)> _shelfInitiate(
  int port,
) async {
  assert(RootIsolateToken.instance == null, "This function must be called from another isolate.");
  final network = NetworkInfo();

  final ip = await network.getWifiIP().then((p) => p!);
  final handler = webSocketHandler((c, [sp]) {
    _handleConnectionQueue.addJob((_) => _handleConnection(c, sp));
  }, pingInterval: const Duration(seconds: 3));

  try {
    final server = await shelf_io.serve(handler, ip, port);
    final hostedPort = server.port;

    if (kDebugMode) {
      print("Serving at $ip:$hostedPort");
    }

    return (server, null);
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print("[_shelfInitiate] Failed to start server: $e");
    }
    return (null, (e, stackTrace));
  }
}

/// Handles the WebSocket connection.
/// A websocket connection is established whenever a client connects to the server.
Future<void> _handleConnection(WebSocketChannel websocketChannel, [String? subprotocol]) async {
  late final MessageChannel messageChannel;
  messageChannel = websocketChannel
      .toMessageChannel(() => _clientChannels.remove((websocketChannel, messageChannel)))

    // Send a status code of 0 to indicate success.
    ..sendPort.send("status", 0);

  unawaited(() async {
    /// This part handles incoming messages from the WebSocket connection.
    ///   It listens for messages and performs actions based on the message type.
    ///   It also handles database method calls.
    while (messageChannel.isOpen) {
      final [name as String, message] = await messageChannel.receivePort.next("invocation");

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
              _notifyEveryoneAboutDatabaseChange(from: websocketChannel, isServerUpdated: true);
            }
          });
          break;
        case _:
          if (kDebugMode) {
            print("Received unexpected message: $message");
          }
          break;
      }
    }
  }());

  if (kDebugMode) {
    print("New connection established. Current connections: ${_clientChannels.length + 1}");
  }

  _clientChannels.add((websocketChannel, messageChannel));
}

/// This sends out a notification to all connected clients about a database change.
/// This also sends the notification to the server as necessary.
Future<void> _notifyEveryoneAboutDatabaseChange({
  required WebSocketChannel? from,
  required bool isServerUpdated,
}) async {
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
