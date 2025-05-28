import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:async_queue/async_queue.dart';
import 'package:easthardware_pms/backend/classes/handshake_connection.dart';
import 'package:easthardware_pms/backend/classes/secure_connection.dart';
import 'package:easthardware_pms/backend/classes/secure_response.dart';
import 'package:easthardware_pms/backend/utils/isolate_indicator.dart';
import 'package:easthardware_pms/backend/utils/random_int_from_date.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:easthardware_pms/utils/try_future.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import "package:shelf/shelf_io.dart" as shelf_io;
import 'package:shelf_router/shelf_router.dart';

const _handshakeLimit = 2;

late final (BigInt, BigInt) _publicKey;
late final (BigInt, BigInt) _privateKey;
late final MessageChannel _channel;
late final AsyncQueue _handleConnectionQueue;
late final AsyncQueue _requestQueue;

late final Map<int, HandshakeConnection> _ongoingHandshakeConnections;
late final Map<int, SecureConnection> _secureConnections;

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
  _requestQueue = AsyncQueue.autoStart();

  // Create the receive port and send it to the main isolate.
  final receivePort = ReceivePort().hostListener();
  sendPort.send("setup", receivePort.sendPort);

  _channel = MessageChannel(receivePort, sendPort);

  _generateKeys();
  _ongoingHandshakeConnections = {};
  _secureConnections = {};

  /// Sweep the handshake connections that are lapsed.
  Timer.periodic(const Duration(minutes: 1), (timer) {
    final now = DateTime.now();
    _ongoingHandshakeConnections.removeWhere((_, connection) => now.isAfter(connection.limit));

    if (kDebugMode) {
      print("Ongoing handshake connections: ${_ongoingHandshakeConnections.length}");
    }
  });

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

  /// This method handles closing the server and the objects created in this isolate.
  Future<void> closeIsolate(String name) async {
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

  /// @MAIN2LANDING:invocation
  _channel.listenAt("invocation", (message) async {
    if (message case [final String returnName, final Object args]) {
      switch (args) {
        case ["stop", ...]:
          closeIsolate(returnName);
          break;
        case ['requestConnection', [final int secureKey]]:
          sendPort.send(returnName, _secureConnections[secureKey]);
          break;
      }
    } else {
      if (kDebugMode) {
        print("Received unexpected message: $message");
      }
    }
  });
}

Future<HttpServer> _initiateLandingServer(int port) async {
  assertChildIsolate();

  final router = Router();

  /// A basic route to check for server availability.
  router.get("/ping", (Request request) => Response.ok("pong"));

  /// Add all necessary routes for handshake.
  _registerHandshakeRoutes(router);

  /// This route is used to request for the websocket port hosted
  ///   by the application in a separate isolate. This is where the
  ///   WebSocket server is hosted.
  router.get("/request-ws-port", secureResponse((request, connection) async {
    final queryParameters = request.url.queryParameters;
    final rawPersistentKey = queryParameters["key"];
    if (rawPersistentKey == null) {
      return SecureResponse.forbidden(
        "Secure key is required.",
        connection.encryptionKey,
      );
    }
    final persistentKey = int.tryParse(rawPersistentKey);
    if (persistentKey == null || !_secureConnections.containsKey(persistentKey)) {
      return SecureResponse.forbidden(
        "Invalid secure key.",
        connection.encryptionKey,
      );
    }

    final pointedConnection = _secureConnections[persistentKey]!;
    if (kDebugMode) {
      printBoxed(
          "pointedConnection: ${(
            encryptionKey: pointedConnection.encryptionKey,
            secureKey: pointedConnection.secureKey,
            isPersistent: pointedConnection.isPersistent
          )}",
          "Secure Connection");
    }
    if (!pointedConnection.isPersistent) {
      return SecureResponse.forbidden(
        "Secure key is not persistent.",
        connection.encryptionKey,
      );
    }

    // If the connection is persistent, we can proceed to request the WebSocket port.
    final port = await _requestWsPort();
    final encoded = jsonEncode({"port": port});

    return SecureResponse.ok(encoded, connection.encryptionKey);
  }));

  final network = NetworkInfo();
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

/// This function generates a pair of keys for asymmetric encryption.
///   This is used by the server to encrypt messages sent to the client,
///   and by the client to encrypt messages sent to the server.
void _generateKeys() {
  final (p, q) = CryptographyService.generateTwoPrimes();
  final n = p * q;
  final phiN = (p - 1) * (q - 1);
  final e = CryptographyService.generateCoprime(phiN);
  final d = CryptographyService.generateModularInverse(e, phiN);

  _publicKey = (BigInt.from(n), BigInt.from(e));
  _privateKey = (BigInt.from(n), BigInt.from(d));

  if (kDebugMode) {
    print("Generated keys:");
    print("  Public Key: $_publicKey");
    print("  Private Key: $_privateKey");
  }
}

/// This function registers the routes that are used in creating a
void _registerHandshakeRoutes(Router router) {
  /// A helper function that validates the handshake key given by the client.
  /// @returns A tuple containing the handshake key if valid, or null if invalid,
  ///   and a boolean indicating whether the key is valid.
  (int?, bool) handshakeKey(String rawKey, int expectedStep) {
    final parsedKey = int.tryParse(rawKey);
    if (parsedKey == null) return (null, false);
    if (!_ongoingHandshakeConnections.containsKey(parsedKey)) return (null, false);

    final now = DateTime.now();
    final connection = _ongoingHandshakeConnections[parsedKey]!;
    if (connection.step != expectedStep) return (null, false);

    final isLapsed = now.isAfter(connection.limit);
    if (isLapsed) {
      _ongoingHandshakeConnections.remove(parsedKey);
      return (null, false);
    }

    return (parsedKey, true);
  }

  /// All handshakes start with a request.
  router.get("/handshake-request", (Request request) {
    if (_ongoingHandshakeConnections.length >= _handshakeLimit) return Response.badRequest();
    final key = randomIntFromDate();
    final isPersistent = request.url.queryParameters["is-persistent"] == "1";
    _ongoingHandshakeConnections[key] = HandshakeConnection(
      step: 0,
      limit: DateTime.now().add(const Duration(minutes: 1)),
      isPersistent: isPersistent,
    );

    return Response.ok(key.toString());
  });

  // Every subsequent connection from this step forward needs the handshake key.

  /// After the client is allowed, a handshake can be initiated.
  ///   STEP 0:
  ///     The client gives a random string 'clientRandom'.
  ///     The server gives a random string 'serverRandom' and its public key.
  router.get("/handshake-initiate/<key>", (Request request, String rawKey) {
    final queryParameters = request.url.queryParameters;
    final (maybeKey, isValid) = handshakeKey(rawKey, 0);
    if (!isValid) return Response.badRequest();

    final key = maybeKey!;
    final clientRandomRaw = queryParameters["client-random"];
    if (clientRandomRaw == null) return Response.badRequest();
    final clientRandom = BigInt.parse(clientRandomRaw);

    final serverRandom = BigInt.from(randomIntFromDate());
    final responseBody = {
      "identity": 1231,
      "serverRandom": serverRandom.toString(),
      "publicKey": [_publicKey.$1.toString(), _publicKey.$2.toString()],
    };

    final connection = _ongoingHandshakeConnections[key]!;
    connection.clientRandom = clientRandom;
    connection.serverRandom = serverRandom;
    connection.step += 1;

    return Response.ok(jsonEncode(responseBody));
  });

  ///   STEP 1:
  ///     The client gives an encrypted random string using the public key.
  ///     The server gives back a random number encrypted using a computed symmetric key.
  router.get("/handshake-premaster/<key>", (Request request, String rawKey) {
    final queryParameters = request.url.queryParameters;
    final (maybeKey, isValid) = handshakeKey(rawKey, 1);
    if (!isValid) return Response.badRequest();

    final key = maybeKey!;
    final encryptedPreMaster = queryParameters["pre-master"];
    if (encryptedPreMaster == null) return Response.badRequest();

    final (n, p) = _privateKey;
    final decodedPreMasterSecret = CryptographyService.decryptAsymmetric(encryptedPreMaster, n, p);
    final preMasterSecret = BigInt.parse(decodedPreMasterSecret);

    final connection = _ongoingHandshakeConnections[key];
    if (connection == null) return Response.badRequest();

    final encryptionKey = (connection.clientRandom! % n) * //
        (connection.serverRandom! % n) *
        (preMasterSecret % n);

    connection.sessionEncryptionKey = encryptionKey;
    connection.preMasterSecret = preMasterSecret;
    connection.step += 1;

    final randomValue = randomIntFromDate().toString();
    connection.randomValue = randomValue;

    return Response.ok(CryptographyService.encryptSymmetric(randomValue, encryptionKey));
  });

  ///   STEP 2:
  ///     The client gives back the decrypted random number.
  ///     The server gives a secure-session key.
  router.get("/handshake-confirmation/<key>", (Request request, String rawKey) {
    final queryParameters = request.url.queryParameters;
    final (maybeKey, isValid) = handshakeKey(rawKey, 2);
    if (!isValid) return Response.badRequest();

    final key = maybeKey!;
    final decryptedRandomValue = queryParameters["decrypted"];
    if (decryptedRandomValue == null) return Response.badRequest();

    final connection = _ongoingHandshakeConnections[key];
    if (connection == null) return Response.badRequest();

    final encryptionKey = connection.sessionEncryptionKey!;
    if (decryptedRandomValue != connection.randomValue) return Response.badRequest();

    // Remove the handshake connection.
    _ongoingHandshakeConnections.remove(key);

    // Create a secure connection.
    final secureSessionKey = randomIntFromDate();
    _secureConnections[secureSessionKey] = SecureConnection(
      secureKey: secureSessionKey,
      encryptionKey: encryptionKey,
      isPersistent: connection.isPersistent,
    );

    return Response.ok("$secureSessionKey");
  });

  ///   STEP *:
  ///     The client tells the server that the session should be closed.
  router.delete("/handshake-remove/<key>", (Request request, String rawKey) {
    final key = int.tryParse(rawKey);
    if (key == null || !_secureConnections.containsKey(key)) return Response.badRequest();

    _secureConnections.remove(key);
    if (kDebugMode) {
      print("Secure connection removed: $key");
    }

    return Response.ok("Connection removed.");
  });
}

/// Creates a shelf handler that processes requests with a secure connection.
///   For a secure connection to be established, the request must contain a valid secure key
///   in the query parameters. The secure key is used to identify the secure connection.
/// Once the [handler] is called, it is assumed that the secure connection is valid
///   and the secure key is removed from the map of secure connections.
Function secureResponse(Future<SecureResponse> Function(Request, SecureConnection) handler) {
  return (Request request) async {
    final rawSecureKey = request.url.queryParameters["secure-key"];
    if (rawSecureKey == null) return Response.forbidden("Secure key is required.");

    // Parse the secure key from the query parameters.
    final secureKey = int.tryParse(rawSecureKey);
    if (secureKey == null || !_secureConnections.containsKey(secureKey)) {
      if (kDebugMode) {
        print("Invalid secure key: $rawSecureKey");
      }
      return Response.forbidden("Invalid secure key.");
    }

    final secureConnection = _secureConnections[secureKey];
    if (secureConnection == null) return Response.forbidden("Provided connection not found.");

    final (response, error) = await handler(request, secureConnection).tryCatch();
    if (error != null) {
      if (kDebugMode) {
        printBoxed(
          "Error in secure response handler: $error",
          "Secure Response Handler",
        );
      }
      return Response.internalServerError(body: "Internal server error.");
    }

    if (!secureConnection.isPersistent) {
      _secureConnections.remove(secureKey);
    }
    return response;
  };
}

/// Requests an object from the main isolate using the provided method and arguments.
///   This sends a message to the main isolate through the "main" channel,
///   and returns a future that completes with the result of the request.
Future<T> _request<T>(String method, [List<Object>? args]) {
  final completer = Completer<T>.sync();

  _requestQueue.addJob((_) async {
    final result = await _channel.invokeNamed<Object>("main", method, args);
    if (result is Exception || result is! T) throw result;
    if (kDebugMode) {
      print("Received result: $result");
    }

    return completer.complete(result as T);
  });

  return completer.future;
}

/// Requests the WebSocket port from the main isolate to establish a WebSocket connection.
Future<int> _requestWsPort() async {
  return _request<int>("requestWsPort");
}
