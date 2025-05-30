/// A utility class for making HTTP requests over a pseudo-TLS secured channel.
///   This class handles a custom handshake mechanism to establish a symmetric encryption key
///   with the server, and then uses that key to encrypt request bodies.
///   This class also caches handshake results to avoid repeated handshakes for the same URI,
///   and provides a way to dispose of sessions after use.
/// Note: This provides a basic level of encryption and is not a replacement for true TLS/SSL.
library;

import 'dart:async';
import 'dart:convert';

import 'package:easthardware_pms/domain/backend/extension_types/secure_keys.dart';
import 'package:easthardware_pms/domain/backend/microservices/key_microservice.dart';
import 'package:easthardware_pms/domain/backend/utils/random_int_from_date.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A typedef for a function that performs a pseudo-TLS handshake.
///   This does not create a timer that automatically disposes of the session.
typedef PublicHandshakeResult = ({
  SessionKey sessionKey,
  EncryptionKey encryptionKey,
  Future<void> Function() dispose,
});

const handshakeCacheTimeout = Duration(minutes: 1);

/// A utility class for making HTTP requests over a pseudo-TLS secured channel.
/// This class handles a custom handshake mechanism to establish a symmetric encryption key
/// with the server, and then uses that key to encrypt request bodies and decrypt response bodies.
///
/// Note: This provides a basic level of encryption and is not a replacement for true TLS/SSL.
/// It's intended for scenarios where standard TLS is not available or feasible, and some
/// protection against casual eavesdropping is desired.
class SecureHttp {
  // Private constructor to prevent instantiation.
  const SecureHttp._();

  /// Sends a GET request to the specified [uri] with the given [headers].
  /// It establishes a secure connection (if not already cached) and decrypts the response body.
  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    // Obtain a secured URI, which includes the session key in query parameters.
    // This also ensures a handshake has occurred and an encryption key is available.
    final (encryptionKey, targetUri) = await _securedUri(uri);
    final response = await http.get(targetUri, headers: headers);

    // Decrypt the response body using the established encryption key.
    return _decryptResponse(response, encryptionKey);
  }

  /// Sends a POST request to the specified [uri] with the given [headers] and [body].
  /// It automatically encrypts the body using the pseudo-TLS handshake and decrypts the response body.
  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final (encryptionKey, targetUri) = await _securedUri(uri);
    final encryptedBody = body?.encryptSymmetric(encryptionKey);
    final response = await http.post(targetUri, headers: headers, body: encryptedBody);

    // Decrypt the response.
    return _decryptResponse(response, encryptionKey);
  }

  /// Sends a DELETE request to the specified [uri] with the given [headers] and [body].
  /// It automatically encrypts the body (if provided) using the pseudo-TLS handshake
  /// and decrypts the response body.
  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final (encryptionKey, targetUri) = await _securedUri(uri);
    final encryptedBody = body?.encryptSymmetric(encryptionKey);
    final response = await http.delete(targetUri, headers: headers, body: encryptedBody);

    // Decrypt the response.
    return _decryptResponse(response, encryptionKey);
  }

  /// Performs a custom pseudo-TLS handshake with the server at [targetUri].
  /// This handshake establishes a shared symmetric [encryptionKey] for the session.
  ///
  /// The process involves several steps:
  /// 1. Request a handshake key from the server.
  /// 2. Initiate the handshake by sending a client random number. The server responds
  ///    with its own random number and its public key.
  /// 3. The client generates a pre-master secret, encrypts it with the server's public key,
  ///    and sends it to the server.
  /// 4. Both client and server derive the same symmetric [encryptionKey] using the client random,
  ///    server random, and the pre-master secret.
  /// 5. The server sends back a value encrypted with the new [encryptionKey] for verification.
  /// 6. The client decrypts this value and sends it back for confirmation.
  /// 7. If successful, the server issues a [sessionKey].
  ///
  /// Returns a tuple containing the [sessionKey], the [encryptionKey], and a [closeSession]
  /// function to terminate the session on the server.
  ///
  /// [isPersistent] indicates whether the established secure session should be kept alive
  /// on the server for multiple requests or closed after a single use.
  static Future<PublicHandshakeResult> pseudoTlsHandshake(
    Uri targetUri, {
    bool isPersistent = false,
  }) async {
    final client = http.Client();
    final address = "${targetUri.scheme}://${targetUri.host}:${targetUri.port}";

    try {
      // Step 0: Request a handshake key from the server.
      // The 'is-persistent' parameter tells the server if this handshake is for a long-lived session.
      final handshakeRequestUri = Uri.parse('$address/handshake-request')
          .replace(queryParameters: {"is-persistent": isPersistent ? "1" : "0"});
      final response1 = await client.get(handshakeRequestUri);
      final handshakeKey = int.parse(response1.body); // This key identifies the handshake process.

      // Step 1 & 2: Client initiates, server responds with public key and its random.
      // The client generates a random number (clientRandom).
      final clientRandom = BigInt.from(randomIntFromDate());
      final handshakeInitiateUri = Uri.parse("$address/handshake-initiate/$handshakeKey")
          .replace(queryParameters: {"client-random": "$clientRandom"});

      final response2 = await client.get(handshakeInitiateUri.replace());
      final decodedResponse2 = jsonDecode(response2.body);

      final BigInt serverRandom; // Server's random number.
      final AsymmetricKey serverPublicKey; // Server's public key.

      // Step 3: Client authenticates server (implicitly by trusting the public key received).
      // In a real TLS, this involves certificate verification. Here, we just parse the response.
      switch (decodedResponse2) {
        case {
            "identity": 1231,
            "serverRandom": final String receivedServerRandom,
            "publicKey": [final String keyN, final String keyE],
          }:
          serverRandom = BigInt.parse(receivedServerRandom);
          serverPublicKey = (BigInt.parse(keyN), BigInt.parse(keyE));
          break;
        case _:
          if (kDebugMode) {
            print(
              'Invalid response for handshake initiation '
              'with key $handshakeKey: $decodedResponse2',
            );
          }
          throw Exception('Invalid response during handshake initiation.');
      }

      // Step 4: Client generates and sends the encrypted pre-master secret.
      // The pre-master secret is another random number generated by the client.
      // Encrypt the pre-master secret using the server's public key (n, e).
      final preMasterSecret = BigInt.from(randomIntFromDate());
      final encryptedPreMasterSecret = "$preMasterSecret".encryptAsymmetric(serverPublicKey);

      // Step 5: Server decrypts the pre-master secret (happens on the server side).
      final preMasterUri = Uri.parse("$address/handshake-premaster/$handshakeKey")
          .replace(queryParameters: {"pre-master": encryptedPreMasterSecret});

      // Step 6: Both client and server generate session keys.
      // The encryption key is derived from clientRandom, serverRandom, and preMasterSecret.
      // All modulo n operations are to ensure the values fit within the cryptographic context,
      // though direct multiplication and then a final modulo might also be an approach.
      // The specific derivation formula here should match the server's derivation.
      final (n, _) = serverPublicKey;
      final encryptionKey = EncryptionKey(
        (clientRandom % n) * (serverRandom % n) * (preMasterSecret % n),
      );

      // Server sends back a value encrypted with the new session key for verification.
      final response3 = await client.get(preMasterUri);
      // Client decrypts this value using its computed session key.
      final decryptedServerVerification = response3.body.decryptSymmetric(encryptionKey);

      // Step 7 & 8: Client and Server confirm readiness.
      // Client sends the decrypted server verification value back to the server.
      final confirmationUri = Uri.parse("$address/handshake-confirmation/$handshakeKey")
          .replace(queryParameters: {"decrypted": decryptedServerVerification});

      final response4 = await client.get(confirmationUri);

      // Step 9: Secure symmetric encryption achieved.
      // The server responds with the final sessionKey for this secure connection.
      final sessionKey = SessionKey(int.parse(response4.body));

      // Function to allow the client to explicitly close/dispose of the session on the server.
      Future<void> dispose() async {
        final removeUri = Uri.parse("$address/handshake-remove");
        // Attempt to tell the server to remove the session. Errors are ignored as it's a cleanup.
        try {
          await http.delete(removeUri, body: "$sessionKey".encryptAsymmetric(serverPublicKey));

          if (kDebugMode) {
            printBoxed("Session $sessionKey disposed successfully", "Handshake Cleanup");
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              "Error disposing session $sessionKey, "
              "server might have already cleaned it up or an error occurred: $e",
            );
          }
        }
      }

      return (
        sessionKey: sessionKey,
        encryptionKey: encryptionKey,
        dispose: dispose,
      );
    } finally {
      client.close();
    }
  }

  /// Cache for storing handshake results.
  /// The outer Expando maps Zones to another Expando.
  /// The inner Expando maps base URIs (scheme://host:port) to their handshake results.
  /// This allows caching handshake results per zone and per server endpoint.
  static final Expando<Expando<_HandshakeResult>> _handshakeCache = Expando();

  /// Retrieves a cached handshake result for the given [uri] or performs a new handshake.
  /// Handshakes are cached based on the base URI (scheme, host, port) and the current [Zone].
  /// Cached handshakes are always requested as persistent.
  static Future<_HandshakeResult> _cachedHandshake(Uri uri) async {
    // Normalize the URI to its base (scheme://host:port) for caching.
    final baseUri = Uri.parse("${uri.scheme}://${uri.host}:${uri.port}");

    // Get or create the Expando for the current Zone.
    final zoneExpando = _handshakeCache[Zone.current] ??= Expando();

    // Get or create the handshake result for the baseUri within the current Zone.
    // If not found, a new persistent handshake is performed.
    final handshake = zoneExpando[baseUri] ??= await _establishNewHandshake(baseUri);

    if (kDebugMode) {
      printBoxed(
        "Session Key: ${handshake.$1}, \nEncryption Key: ${handshake.$2}",
        "Cached Handshake result for $baseUri",
      );
    }

    // Unpack the result of the cached or new handshake.
    final (sessionKey, encryptionKey, dispose, timer) = handshake;

    // Replace the timer with a new one to ensure the session is disposed of.
    timer.cancel();
    final newTimer = Timer(handshakeCacheTimeout, dispose.call);

    return (sessionKey, encryptionKey, dispose, newTimer);
  }

  /// Creates a new handshake with the server at the given [baseUri].
  ///   This function also sets up a timer to dispose of the session after 1 minute.
  static Future<_HandshakeResult> _establishNewHandshake(Uri baseUri) async {
    // Cached handshakes are intended to be persistent.
    final handshakeResult = await pseudoTlsHandshake(baseUri, isPersistent: true);
    final (:sessionKey, :encryptionKey, :dispose) = handshakeResult;
    final timer = Timer(handshakeCacheTimeout, dispose.call);

    return (sessionKey, encryptionKey, dispose, timer);
  }

  /// Prepares a URI for a secure request by ensuring a handshake is
  ///   established (or retrieved from cache) and adding the `secure-key`
  ///   query parameter to the URI.
  ///
  /// Returns the session key, encryption key, dispose function,
  ///   and the modified target URI.
  static Future<_SecuredUriResult> _securedUri(Uri uri) async {
    final (sessionKey, encryptionKey, _, timer) = await _cachedHandshake(uri);

    // Add the 'secure-key' to the original URI's query parameters.
    // This key allows the server to identify the secure session.
    final queryParameters = {"secure-key": "$sessionKey", ...uri.queryParameters};
    final targetUri = uri.replace(queryParameters: queryParameters);

    return (encryptionKey, targetUri);
  }

  /// Decrypts an HTTP response body using the provided [encryptionKey].
  /// Returns a new [http.Response] with the decrypted body and original metadata.
  static http.Response _decryptResponse(
    http.Response response,
    EncryptionKey encryptionKey,
  ) {
    return http.Response(
      CryptographyService.decryptSymmetric(response.body, encryptionKey),
      response.statusCode,
      headers: response.headers,
      request: response.request,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

/// Typedef for the result of a successful pseudo-TLS handshake.
/// Contains the session key, the derived encryption key, and a function to dispose of the session.
typedef _HandshakeResult = (
  SessionKey sessionKey,
  EncryptionKey encryptionKey,
  Future<void> Function() dispose,
  Timer timer,
);

/// Typedef for the result of a secured URI request.
/// Contains the session key, the encryption key, a dispose function,
///   and the modified target URI.
typedef _SecuredUriResult = (EncryptionKey encryptionKey, Uri targetUri);
