/// This isolate-based microservice handles the generation of asymmetric keys.
library;

import 'dart:async';
import 'dart:isolate';

import 'package:easthardware_pms/domain/backend/utils/isolate_indicator.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef AsymmetricKey = (BigInt, BigInt);
typedef AsymmetricKeys = (AsymmetricKey, AsymmetricKey);

const mainIsolate = Object();
const childIsolate = Object();

@mainIsolate
bool _hasSetup = false;

@mainIsolate
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

  final (publicKey, privateKey) = await _channel.invoke<AsymmetricKeys>("requestKeys");
  _publicKey = publicKey;
  _privateKey = privateKey;

  await _channel.invoke("stop");

  if (kDebugMode) {
    printBoxed(
      "Public Key: $_publicKey\nPrivate Key: $_privateKey",
      "Generated Keys Microservice",
    );
  }

  TextFormBox();
}

Future<AsymmetricKey> get publicKey async {
  assertMainIsolate();

  return _publicKey;
}

Future<AsymmetricKey> get privateKey async {
  assertMainIsolate();

  return _privateKey;
}

Future<AsymmetricKeys> get keys async {
  assertMainIsolate();

  return (_publicKey, _privateKey);
}

@childIsolate
late final AsymmetricKey _publicKey;

@childIsolate
late final AsymmetricKey _privateKey;

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
  final localChannel = DisposableMessageChannel(sendPort);
  sendPort.send("setup", localChannel.receivePort.sendPort);
  sendPort.send("setup", 0);

  /// Generate the asymmetric keys to be used.
  _generateKeys();

  /// @MAIN2MS_KEYS:invocation
  localChannel.listenFrom("invocation", (message) async {
    if (kDebugMode) {
      printBoxed(message, "MAIN2MS_KEYS:invocation");
    }

    if (message case [final String returnName, final Object args]) {
      switch (args) {
        case ["stop", _]:
          localChannel.close();
          sendPort.send(returnName, 0);
          break;
        case ['requestKeys', _]:
          sendPort.send(returnName, (_publicKey, _privateKey));
          break;
      }

      return;
    }

    if (kDebugMode) {
      print("Received unexpected message: $message");
    }
  });
}

/// This function generates a pair of keys for asymmetric encryption.
///   This is used by the server to encrypt messages sent to the client,
///   and by the client to encrypt messages sent to the server.
void _generateKeys() {
  assertChildIsolate();

  final (publicKey, privateKey) = CryptographyService.generateKeyPair();

  _publicKey = publicKey;
  _privateKey = privateKey;

  if (kDebugMode) {
    printBoxed(
      "Public Key: $_publicKey\nPrivate Key: $_privateKey",
      "Generated Keys Microservice",
    );
  }
}
