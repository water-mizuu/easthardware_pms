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

const otherIsolate = Object();

/// Hosts a shelf server on the given port.
/// Returns a tuple containing the server channel, the port, and a function to close the server.
/// - The server channel is used to communicate with the server.
/// - The port is the port on which the server is hosted.
/// - The close function is used to stop the server.
Future<(ServerChannel, int, Future<void> Function() close)> hostShelfServer(int port) async {
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

  assert(receivedServerPort == port, "The server port is not the same as the one provided.");

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
      final result = await handleDbMethod(method, arguments);
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
      final result = await handleDbMethod(method, arguments);
      serverChannel.sendPort.send(result);
    } else {
      if (kDebugMode) {
        print("Received unexpected message: $result");
      }
    }
  } while (running);
}
