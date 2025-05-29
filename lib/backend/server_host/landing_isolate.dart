import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:async_queue/async_queue.dart';
import 'package:easthardware_pms/backend/classes/handshake_connection.dart';
import 'package:easthardware_pms/backend/classes/secure_connection.dart';
import 'package:easthardware_pms/backend/classes/secure_response.dart';
import 'package:easthardware_pms/backend/extension_types/secure_keys.dart';
import 'package:easthardware_pms/microservices/key_microservice.dart';
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
late final MessageChannel _mainChannel;
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

  _mainChannel = MessageChannel(receivePort, sendPort);

  /// Sweep the handshake connections that are lapsed.
  Timer.periodic(const Duration(minutes: 1), (timer) {
    final now = DateTime.now();
    final countBeforeSweep = _ongoingHandshakeConnections.length;
    _ongoingHandshakeConnections.removeWhere((_, connection) => now.isAfter(connection.limit));
    final countAfterSweep = _ongoingHandshakeConnections.length;

    if (kDebugMode) {
      if (countBeforeSweep != countAfterSweep) {
        print("Ongoing handshake connections: ${_ongoingHandshakeConnections.length}");
      }
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

  /// After the server is set up, we can generate the keys.
  await _generateKeys();
  _ongoingHandshakeConnections = {};
  _secureConnections = {};

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
  _mainChannel.listenFrom("invocation", (message) async {
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
Future<void> _generateKeys() async {
  final (public, private) = await _mainChannel.invokeNamed<AsymmetricKeys>("main", "requestKeys");

  _publicKey = public;
  _privateKey = private;

  if (kDebugMode) {
    printBoxed(
      "Generated keys:\n"
          "  Public Key: ${_publicKey.$1}, ${_publicKey.$2}\n"
          "  Private Key: ${_privateKey.$1}, ${_privateKey.$2}",
      "Key Generation",
    );
  }
}

/// Registers the routes related to the handshake process.
/// This includes routes for initiating, progressing, and confirming the handshake.
void _registerHandshakeRoutes(Router router) {
  /// A helper function that validates the handshake key given by the client.
  /// It checks if the key exists, if the handshake step is correct, and if the handshake has not expired.
  /// @returns A tuple containing the handshake key if valid, or null if invalid,
  ///   and a boolean indicating whether the key is valid.
  (int?, bool) handshakeKey(String rawKey, int expectedStep) {
    // Attempt to parse the raw key string into an integer.
    final parsedKey = int.tryParse(rawKey);
    // If parsing fails, the key is invalid.
    if (parsedKey == null) return (null, false);
    // Check if there's an ongoing handshake associated with this key.
    if (!_ongoingHandshakeConnections.containsKey(parsedKey)) return (null, false);

    final now = DateTime.now();
    final connection = _ongoingHandshakeConnections[parsedKey]!;
    // Verify that the current handshake step matches the expected step.
    if (connection.step != expectedStep) return (null, false);

    // Check if the handshake time limit has been exceeded.
    final isLapsed = now.isAfter(connection.limit);
    if (isLapsed) {
      // If lapsed, remove the connection and mark as invalid.
      _ongoingHandshakeConnections.remove(parsedKey);
      return (null, false);
    }

    // If all checks pass, the key is valid.
    return (parsedKey, true);
  }

  /// All handshakes start with a request to this endpoint.
  /// It generates a unique key for the handshake and stores it with a time limit.
  router.get("/handshake-request", (Request request) {
    // Limit the number of ongoing handshakes to prevent resource exhaustion.
    if (_ongoingHandshakeConnections.length >= _handshakeLimit) {
      return Response.badRequest(body: "Handshake limit reached.");
    }
    // Generate a unique key based on the current date and time.
    final key = randomIntFromDate();
    // Check if the client requested a persistent connection.
    final isPersistent = request.url.queryParameters["is-persistent"] == "1";
    // Store the new handshake connection details.
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
  ///     The client gives a random string 'client-random'.
  ///     The server gives a random string 'serverRandom' and its public key.
  router.get("/handshake-initiate/<key>", (Request request, String rawKey) {
    final queryParameters = request.url.queryParameters;
    // Validate the provided handshake key and ensure it's for step 0.
    final (maybeKey, isValid) = handshakeKey(rawKey, 0);
    if (!isValid) return Response.badRequest(body: "Invalid or expired handshake key for step 0.");

    // Retrieve the client's random number from the query parameters.
    final clientRandomRaw = queryParameters["client-random"];
    if (clientRandomRaw == null) {
      return Response.badRequest(body: "Missing 'client-random' parameter.");
    }

    final key = maybeKey!;
    final clientRandom = BigInt.parse(clientRandomRaw);

    // Generate the server's random number.
    final serverRandom = BigInt.from(randomIntFromDate());
    // Prepare the response body with server identity, server random, and public key.
    final responseBody = {
      "identity": 1231, // Placeholder for server identity/version.
      "serverRandom": serverRandom.toString(),
      "publicKey": [_publicKey.$1.toString(), _publicKey.$2.toString()],
    };

    // Update the handshake connection with the client and server randoms, and advance the step.
    final connection = _ongoingHandshakeConnections[key]!;
    connection.clientRandom = clientRandom;
    connection.serverRandom = serverRandom;
    connection.step += 1;

    return Response.ok(jsonEncode(responseBody));
  });

  ///   STEP 1: Client sends an encrypted pre-master secret.
  ///     The client encrypts a pre-master secret using the server's public key.
  ///     The server decrypts it and computes a symmetric session key.
  ///     The server then sends back a random value encrypted with this new session key.
  router.get("/handshake-premaster/<key>", (Request request, String rawKey) {
    final queryParameters = request.url.queryParameters;
    // Validate the provided handshake key and ensure it's for step 1.
    final (maybeKey, isValid) = handshakeKey(rawKey, 1);
    if (!isValid) return Response.badRequest(body: "Invalid or expired handshake key for step 1.");

    final key = maybeKey!;
    // Retrieve the encrypted pre-master secret from the query parameters.
    final encryptedPreMaster = queryParameters["pre-master"];
    if (encryptedPreMaster == null) {
      return Response.badRequest(body: "Missing 'pre-master' parameter.");
    }

    // Decrypt the pre-master secret using the server's private key.
    final (n, d) = _privateKey; // Unpack private key components (modulus, private exponent).
    final decodedPreMasterSecret = encryptedPreMaster.decryptAsymmetric(n, d);
    final preMasterSecret = BigInt.parse(decodedPreMasterSecret);

    final connection = _ongoingHandshakeConnections[key];
    if (connection == null) {
      // Should be caught by handshakeKey, but as a safeguard.
      return Response.badRequest(body: "Handshake connection not found.");
    }

    // Compute the symmetric encryption key using client random, server random, and pre-master secret.
    // This ensures both client and server arrive at the same session key.
    final encryptionKey = EncryptionKey((connection.clientRandom! % n) * //
        (connection.serverRandom! % n) *
        (preMasterSecret % n));

    // Store the session encryption key and pre-master secret in the connection object.
    connection.sessionEncryptionKey = encryptionKey;
    connection.preMasterSecret = preMasterSecret;
    // Advance the handshake step.
    connection.step += 1;

    // Generate a random value to be sent back to the client, encrypted with the new session key.
    // This allows the client to verify that the server also correctly computed the session key.
    final randomValue = randomIntFromDate().toString();
    connection.randomValue = randomValue; // Store for later verification.

    // Encrypt the random value using the computed symmetric session key.
    return Response.ok(randomValue.encryptSymmetric(encryptionKey));
  });

  ///   STEP 2: Client confirms by sending back the decrypted random value.
  ///     The client decrypts the random value received from the server using the session key.
  ///     If the decrypted value matches, the handshake is successful.
  ///     The server then issues a secure session key.
  router.get("/handshake-confirmation/<key>", (Request request, String rawKey) {
    final queryParameters = request.url.queryParameters;
    // Validate the provided handshake key and ensure it's for step 2.
    final (maybeKey, isValid) = handshakeKey(rawKey, 2);
    if (!isValid) return Response.badRequest(body: "Invalid or expired handshake key for step 2.");

    final key = maybeKey!;
    // Retrieve the decrypted random value from the client.
    final decryptedRandomValue = queryParameters["decrypted"];
    if (decryptedRandomValue == null) {
      return Response.badRequest(body: "Missing 'decrypted' parameter.");
    }

    final connection = _ongoingHandshakeConnections[key];
    if (connection == null) {
      return Response.badRequest(body: "Handshake connection not found."); // Safeguard.
    }

    final encryptionKey = connection.sessionEncryptionKey!;
    // Verify that the decrypted random value from the client matches the one stored by the server.
    if (decryptedRandomValue != connection.randomValue) {
      return Response.badRequest(body: "Handshake confirmation failed: decrypted value mismatch.");
    }

    // Handshake successful, remove the temporary handshake connection.
    _ongoingHandshakeConnections.remove(key);

    // Create a new secure connection using the established session encryption key.
    final secureSessionKey = randomIntFromDate(); // Generate a new key for this secure session.
    _secureConnections[secureSessionKey] = SecureConnection(
      secureKey: secureSessionKey,
      encryptionKey: encryptionKey, // Use the symmetric key derived during handshake.
      isPersistent: connection.isPersistent, // Honor the persistence request from handshake start.
    );

    // Send the new secure session key to the client.
    return Response.ok("$secureSessionKey");
  });

  ///   STEP *: Client requests to close/remove the secure session.
  ///     The client can explicitly request the server to remove an active secure session.
  router.delete("/handshake-remove", (Request request) async {
    final (rawKey, error) = await request.readAsString().tryCatch();
    if (error != null) {
      if (kDebugMode) {
        print("Error reading request body: $error");
      }
      return Response.badRequest(body: "Failed to read request body: $error");
    }

    final (n, d) = _privateKey; // Unpack private key components (modulus, private exponent).
    final encryptedKey = rawKey!.trim();
    final decryptedKey = encryptedKey.decryptAsymmetric(n, d);
    final key = int.tryParse(decryptedKey);
    // Validate that the key is an integer and corresponds to an existing secure connection.
    if (key == null || !_secureConnections.containsKey(key)) {
      return Response.badRequest(body: "Invalid or non-existent secure key for removal.");
    }

    // Remove the specified secure connection.
    _secureConnections.remove(key);
    if (kDebugMode) {
      print("Secure connection removed: $key");
    }

    return Response.ok("Connection removed.");
  });
}

/// Creates a shelf handler that processes requests with a secure connection.
///   This acts as a middleware to ensure that incoming requests for certain routes
///   are authenticated with a valid secure session key.
///   For a secure connection to be established, the request must contain a valid secure key
///   in the query parameters ('secure-key'). The secure key is used to identify the secure connection.
/// Once the [handler] is called, it is assumed that the secure connection is valid.
///   If the connection is not persistent, the secure key is removed from the map of
///   secure connections after the handler completes.
Function secureResponse(Future<SecureResponse> Function(Request, SecureConnection) handler) {
  return (Request request) async {
    // Extract the 'secure-key' from the request's query parameters.
    final rawSecureKey = request.url.queryParameters["secure-key"];
    if (rawSecureKey == null) return Response.forbidden("Secure key is required.");

    // Parse the secure key from the query parameters.
    final secureKey = int.tryParse(rawSecureKey);
    // Validate that the parsed key is not null and exists in our active secure connections.
    if (secureKey == null || !_secureConnections.containsKey(secureKey)) {
      if (kDebugMode) {
        print("Invalid secure key: $rawSecureKey");
      }
      return Response.forbidden("Invalid secure key.");
    }

    final secureConnection = _secureConnections[secureKey];
    // This check is somewhat redundant due to the previous containsKey, but good for safety.
    if (secureConnection == null) return Response.forbidden("Provided connection not found.");

    // Execute the actual request handler, passing the request and the validated secure connection.
    final (response, error) = await handler(request, secureConnection).tryCatch();
    if (error != null) {
      // Log the error if in debug mode.
      if (kDebugMode) {
        printBoxed(
          "Error in secure response handler: $error",
          "Secure Response Handler",
        );
      }
      // Return a generic internal server error to the client.
      return Response.internalServerError(body: "Internal server error.");
    }

    // If the secure connection is not marked as persistent, remove it after use.
    // This is for single-use or short-lived secure operations.
    if (!secureConnection.isPersistent) {
      _secureConnections.remove(secureKey);
    }
    // Return the response obtained from the handler.
    return response;
  };
}

/// Requests an object from the main isolate using the provided method and arguments.
///   This sends a message to the main isolate through the pre-established message channel (`_channel`),
///   targeting the "main" listener on the other side.
///   It returns a future that completes with the result of the request from the main isolate.
///   Requests are queued to ensure orderly processing.
Future<T> _request<T>(String method, [List<Object>? args]) {
  final completer = Completer<T>.sync();

  // Add the request to a queue to handle them one by one.
  // This prevents race conditions or overwhelming the main isolate if many requests are made concurrently.
  _requestQueue.addJob((_) async {
    // Invoke the named method on the main isolate via the message channel.
    final result = await _mainChannel.invokeNamed<Object>("main", method, args);
    // Check if the result is an error or not of the expected type.
    if (result is Exception || result is! T) throw result; // Propagate errors or type mismatches.
    if (kDebugMode) {
      print("Received result from main isolate for '$method': $result");
    }

    // Complete the future with the successful result.
    return completer.complete(result as T);
  });

  return completer.future;
}

/// Convenience method to request the WebSocket port from the main isolate.
///   This is a specific use case of the generic `_request` method.
Future<int> _requestWsPort() async {
  // Calls the `_request` method, specifically asking for "requestWsPort".
  return _request<int>("requestWsPort");
}
