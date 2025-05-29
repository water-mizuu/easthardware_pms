/// This isolate-based microservice handles the generation of asymmetric keys.
library;

import 'dart:async';
import 'dart:isolate';

import 'package:easthardware_pms/backend/utils/isolate_indicator.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef AsymmetricKey = (BigInt, BigInt);
typedef AsymmetricKeys = (AsymmetricKey, AsymmetricKey);

const mainIsolate = Object();
const childIsolate = Object();

@mainIsolate
bool _hasSetup = false;

@childIsolate
late final AsymmetricKey _publicKey;

@childIsolate
late final AsymmetricKey _privateKey;

@mainIsolate
@childIsolate
late final MessageChannel _channel;

Future<void> setupKeyMicroService() async {
  assertMainIsolate();

  if (_hasSetup) {
    return;
  }

  final receivePort = ReceivePort().hostListener();
  final payload = (RootIsolateToken.instance!, receivePort.sendPort);
  await Isolate.spawn(_spawnKeyMicroserviceIsolate, payload);

  /// The first message sent from the isolate is the [SendPort] of the isolate.
  final sendPort = await receivePort.next<NamedSendPort>("setup");

  /// Next, a status code or an error is sent from the isolate.
  final status = await receivePort.next<Object>("setup");
  if (status case (final Object error, final StackTrace stackTrace)) {
    Error.throwWithStackTrace(error, stackTrace);
  }
  assert(status == 0, "The isolate should yield 0 after spawning properly.");

  /// When everything is correct, we can create a [MessageChannel]
  ///   to communicate with the isolate.
  _channel = MessageChannel(receivePort, sendPort);
  _hasSetup = true;
}

Future<AsymmetricKey> get publicKey async {
  assertMainIsolate();
  final (publicKey, _) = await _channel.invoke<AsymmetricKeys>("requestKeys");

  return publicKey;
}

Future<AsymmetricKey> get privateKey async {
  assertMainIsolate();
  final (_, privateKey) = await _channel.invoke<AsymmetricKeys>("requestKeys");

  return privateKey;
}

Future<AsymmetricKeys> get keys async {
  assertMainIsolate();

  return await _channel.invoke<AsymmetricKeys>("requestKeys");
}

/// Spawns an isolate to handle database operations and WebSocket connections.
///   This isolate will handle incoming messages and perform database operations
///   as needed.
Future<void> _spawnKeyMicroserviceIsolate((RootIsolateToken, NamedSendPort) payload) async {
  assertChildIsolate();

  // Unpack the arguments
  final (token, sendPort) = payload;

  // Ensure messenger to allow communication.
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  // Create the receive port and send it to the main isolate.
  _channel = DisposableMessageChannel(sendPort);
  sendPort.send("setup", _channel.receivePort.sendPort);
  sendPort.send("setup", 0);

  _generateKeys();

  /// @MAIN2LANDING:invocation
  _channel.listenFrom("invocation", (message) async {
    if (message case [final String returnName, final Object args]) {
      switch (args) {
        case ["stop", ...]:
          (_channel as DisposableMessageChannel).close();
          break;
        case ['requestKeys', _]:
          sendPort.send(returnName, (_publicKey, _privateKey));
          break;
      }
    } else {
      if (kDebugMode) {
        print("Received unexpected message: $message");
      }
    }
  });
}

/// This function generates a pair of keys for asymmetric encryption.
///   This is used by the server to encrypt messages sent to the client,
///   and by the client to encrypt messages sent to the server.
void _generateKeys() {
  assertChildIsolate();

  final (p, q) = CryptographyService.generateTwoPrimes();
  final n = p * q;
  final phiN = (p - 1) * (q - 1);
  final e = CryptographyService.generatePrimeLessThanRootOf(phiN);
  final d = CryptographyService.generateModularInverse(e, phiN);

  _publicKey = (BigInt.from(n), BigInt.from(e));
  _privateKey = (BigInt.from(n), BigInt.from(d));

  if (kDebugMode) {
    printBoxed(
      "Public Key: $_publicKey\nPrivate Key: $_privateKey",
      "Generated Keys -- Microservice",
    );
  }
}
