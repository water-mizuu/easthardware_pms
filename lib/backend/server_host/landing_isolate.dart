import 'dart:async';
import 'dart:convert' show jsonEncode;
import 'dart:io';
import 'dart:isolate';

import 'package:async_queue/async_queue.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart' show AuthenticationException;
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:easthardware_pms/utils/try_future.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import "package:shelf/shelf_io.dart" as shelf_io;
import 'package:shelf_router/shelf_router.dart';

late MessageChannel channel;
late AsyncQueue _handleConnectionQueue;

/// Spawns an isolate to handle database operations and WebSocket connections.
///   This isolate will handle incoming messages and perform database operations
///   as needed.
Future<void> spawnLandingIsolate((RootIsolateToken, NamedSendPort, int port) payload) async {
  assert(RootIsolateToken.instance == null, "This function must be called from another isolate.");

  // Unpack the arguments
  final (token, sendPort, port) = payload;

  // Ensure messenger to allow communication.
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  // Instantiate the queue to handle connections atomically.
  _handleConnectionQueue = AsyncQueue.autoStart();

  // Create the receive port and send it to the main isolate.
  final receivePort = ReceivePort().hostListener();
  sendPort.send("setup", receivePort.sendPort);

  channel = MessageChannel(receivePort, sendPort);

  // Start a shelf server on any port.
  final (server, error) = await _initiateLandingServer(port).tryCatch();
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
  unawaited(() async {
    var run = true;

    /// This method handles closing the server and the objects created in this isolate.
    Future<void> closeIsolate(String name) async {
      run = false;

      // Close the shelf server
      await server.close(force: true);

      // Clear the async queues
      _handleConnectionQueue.clear();

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
        }
      } else {
        if (kDebugMode) {
          print("Received unexpected message: $message");
        }
      }
    }
  }());
}

Future<HttpServer> _initiateLandingServer(int port) async {
  assert(RootIsolateToken.instance == null, "This function must be called from another isolate.");
  final network = NetworkInfo();

  final router = Router();
  router.get("/ping", (Request request) {
    final completer = Completer<Response>.sync();
    _handleConnectionQueue.addJob((_) async {
      completer.complete(Response.ok("pong"));
    });

    return completer.future;
  });

  /// TODO: Make it so that it requires a sesion token.
  router.get("/request-ws-port", (Request request) {
    final completer = Completer<Response>.sync();
    _handleConnectionQueue.addJob((_) async {
      final port = await _requestWsPort();
      completer.complete(Response.ok(port.toString()));
    });

    return completer.future;
  });

  router.get("/auth", (Request request) {
    final query = request.url.queryParameters;
    final completer = Completer<Response>.sync();
    _handleConnectionQueue.addJob((_) async {
      final username = query["username"];
      if (username == null) {
        return completer.complete(Response.badRequest(body: "Invalid credentials"));
      }

      final password = query["password"];
      if (password == null) {
        return completer.complete(Response.badRequest(body: "Invalid credentials 1"));
      }

      final (res, err1) = await _requestComparisonAuth(username).tryCatch();
      if (err1 != null) {
        if (kDebugMode) {
          print(err1);
        }
        return completer.complete(Response.badRequest(body: "Invalid credentials 2"));
      }
      final [hash, salt] = res!;
      final inputHash = CryptographyService.generateHash(query["password"]!, salt);

      if (inputHash.toString() != hash.toString()) {
        return completer.complete(Response.badRequest(body: "Invalid credentials 3"));
      }

      final id = await _requestUserId(username);
      final sessionToken = await _requestSessionToken(id);
      final response = jsonEncode({"sessionToken": sessionToken, "user_id": id});

      completer.complete(Response.ok(response));
    });

    return completer.future;
  });

  final ip = await network.getWifiIP().then((p) => p!);
  final handler = const Pipeline() //
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, ip, port);
  final hostedPort = server.port;

  if (kDebugMode) {
    print("Serving at $ip:$hostedPort");
  }

  return server;
}

Future<int> _requestSessionToken(int userId) async {
  final result = await channel.invokeNamed<Object>("main", "requestSessionToken", [userId]);
  if (result is AuthenticationException) throw result;
  if (kDebugMode) {
    print("Received result: $result");
  }

  return result as int;
}

Future<int> _requestUserId(String username) async {
  final result = await channel.invokeNamed<Object>("main", "requestUserId", [username]);
  if (result is AuthenticationException) throw result;
  if (kDebugMode) {
    print("Received result: $result");
  }

  return result as int;
}

Future<List<Uint8List>> _requestComparisonAuth(String username) async {
  final [hashed, salt] = await channel //
      .invokeNamed<List<Uint8List>>("main", "requestComparisonAuth", [username]);

  return [hashed, salt];
}

Future<int> _requestWsPort() async {
  final result = await channel.invokeNamed<int>("main", "requestWsPort", []);
  if (kDebugMode) {
    print("Received result: $result");
  }

  return result;
}
