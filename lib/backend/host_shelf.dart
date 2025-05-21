/// This library contains the code which hosts a shelf server
///   through a background isolate.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:async_queue/async_queue.dart';
import 'package:easthardware_pms/backend/database.dart';
import 'package:easthardware_pms/backend/extensions/to_server_channel.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:easthardware_pms/utils/server_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import "package:shelf/shelf_io.dart" as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Hosts a shelf server on the given port.
/// Returns a tuple containing the server channel, the port, and a function to close the server.
/// - The server channel is used to communicate with the server.
/// - The port is the port on which the server is hosted.
/// - The close function is used to stop the server.
Future<(ServerChannel, int, Future<void> Function() close)> hostShelfServer(int port) async {
  /// Create a receive port to communicate with the isolate.
  final receivePort = ReceivePort().hostListener();

  /// Spawn an isolate which hosts the server.
  await Isolate.spawn(_spawnIsolate, (
    RootIsolateToken.instance!,
    receivePort.sendPort,
    port,
  ));

  /// The first message sent from the isolate is the [SendPort] of the isolate.
  final sendPort = await receivePort.next<SendPort>();

  /// Next, a status code or an error is sent from the isolate.
  final status = await receivePort.next<Object>();
  if (status case (Object error, StackTrace stackTrace)) {
    Error.throwWithStackTrace(error, stackTrace);
  }
  assert(status == 0, "The isolate should yield 0 after spawning properly.");

  final receivedServerPort = await receivePort.next<int>();
  assert(receivedServerPort == port, "The server port is not the same as the one provided.");

  /// When everything is correct, we can create a [ServerChannel] to communicate with the isolate.
  final channel = ServerChannel(receivePort, sendPort);

  /// We create a dispose function to stop the isolate.
  ///   This allows us to not expose the isolate itself to the user.
  // ignore: prefer_function_declarations_over_variables
  final dispose = () async {
    final status = await channel.invoke("stop");
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
  };

  return (channel, port, dispose);
}

late AsyncQueue _asyncQueue;

/// Spawns an isolate to handle database operations and WebSocket connections.
///   This isolate will handle incoming messages and perform database operations
///   as needed.
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
  } else if (server != null) {
    sendPort.send(0);
  }

  // Send the server port back to the main isolate.
  //  The main isolate compares the port to the one provided.
  sendPort.send(server!.port);

  /// This method handles closing the server and the objects created in this isolate.
  void closeIsolate() async {
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
  }

  void handleDbCall(String method, List<Object?> arguments) async {
    final result = await handleDbMethod(method, arguments);
    sendPort.send(result);
  }

  /// Listen for messages from the main isolate.
  receivePort.listen((message) {
    if (message case ["stop", ...]) {
      closeIsolate();
    } else if (message case ["db", [String method, List<Object?> arguments]]) {
      handleDbCall(method, arguments);
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
Future<(HttpServer?, Object?)> _shelfInitiate(
  int port,
  FutureOr<void> Function(WebSocketChannel channel, [String? subprotocol]) onConnect,
) async {
  assert(RootIsolateToken.instance == null, "This function must be called from another isolate.");
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
      print("[_shelfInitiate] Failed to start server: $e");
    }
    return (null, (e, stackTrace));
  }
}

/// Handles the WebSocket connection.
/// A websocket connection is established whenever a client connects to the server.
Future<void> _handleConnection(WebSocketChannel channel, [String? subprotocol]) async {
  // Handle WebSocket connection

  final serverChannel = channel.toServerChannel() //
    // Send a status code of 0 to indicate success.
    ..sendPort.send(0);

  serverChannel.receivePort.listen((message) {
    if (message case ["db", [String method, List<Object?> arguments]]) {
      // Handle each db method call.
      final result = handleDbMethod(method, arguments);
      serverChannel.sendPort.send(result);
    } else {
      if (kDebugMode) {
        print("Received unexpected message: $message");
      }
    }
  });
}
