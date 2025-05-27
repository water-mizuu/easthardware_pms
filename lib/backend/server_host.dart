/// This library contains the code which hosts a shelf server(s)
///   through a background isolate.
library;

import 'dart:async';
import 'dart:isolate';

import 'package:easthardware_pms/backend/server_host/landing_isolate.dart';
import 'package:easthardware_pms/backend/server_host/web_socket_isolate.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'extension_types/shelf_server.dart';

/// Hosts a shelf server on the given port.
/// Returns a tuple containing the server channel, and a function to close the server.
/// - The server channel is used to communicate with the server.
/// - The close function is used to stop the server.
Future<(ShelfServer landing, ShelfServer webSocket, Stream<ServerEvent> events)> //
    hostShelfServer(int port) async {
  //
  final streamController = StreamController<ServerEvent>.broadcast();
  final (landingServer, webSocketServer) = await (
    hostLandingServer(port),
    hostWebSocketServer(),
  ).wait;

  /// Handle calls from the landing isolate.
  unawaited(() async {
    final channel = landingServer.channel;
    while (channel.isOpen) {
      final (name, message) = await channel.receiveNamed('main');
      if (kDebugMode) {
        print("*" * 20);
        print("[LANDING@MAIN] Received message: $message");
        print("*" * 20);
      }

      switch (message) {
        case ['requestWsPort', _]:
          channel.send(name, webSocketServer.port);
      }
    }
  }());

  /// Handle calls from the webSocket isolate.
  unawaited(() async {
    final channel = webSocketServer.channel;
    while (channel.isOpen) {
      final message = await channel.receive('main');
      if (kDebugMode) {
        print("*" * 20);
        print("[LANDING@MAIN] Received message: $message");
        print("*" * 20);
      }

      switch (message) {
        case ['didUpdate', final int msSinceEpoch]:
          final dateTime = DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
          if (kDebugMode) {
            print("Server updated at: $dateTime");
          }
          streamController.add(ServerDatabaseUpdated(lastUpdated: dateTime));
          break;
      }
    }
  }());

  /// TODO: Add a method on close.

  return (landingServer, webSocketServer, streamController.stream);
}

Future<ShelfServer> hostLandingServer(int port) async {
  final receivePort = ReceivePort().hostListener();

  final isolate = await Isolate.spawn(spawnLandingIsolate, (
    RootIsolateToken.instance!,
    receivePort.sendPort,
    port,
  ));

  /// The first message sent from the isolate is the [SendPort] of the isolate.
  final sendPort = await receivePort.next<NamedSendPort>("setup");

  /// Next, a status code or an error is sent from the isolate.
  final status = await receivePort.next<Object>("setup");
  if (status case (final Object error, final StackTrace stackTrace)) {
    Error.throwWithStackTrace(error, stackTrace);
  }
  assert(status == 0, "The isolate should yield 0 after spawning properly.");

  final hostedPort = await receivePort.next<int>("setup");
  assert(hostedPort == port, "The port should match the one provided.");

  /// When everything is correct, we can create a [MessageChannel] to communicate with the isolate.
  final channel = MessageChannel(receivePort, sendPort);

  Future<void> dispose() async {
    final status = await channel.invoke("stop");
    switch (status) {
      case 0:
        if (kDebugMode) {
          print("Isolate stopped successfully.");
        }
        receivePort.close();
        isolate.kill(priority: Isolate.immediate);
        break;
      case _:
        if (kDebugMode) {
          print("Failed to stop the isolate.");
        }
        break;
    }
  }

  return ShelfServer(channel, hostedPort, dispose);
}

Future<ShelfServer> hostWebSocketServer() async {
  /// Create a receive port to communicate with the isolate.
  final receivePort = ReceivePort().hostListener();

  /// Spawn the webSocket isolate which hosts the server.
  final isolate = await Isolate.spawn(spawnWebSocketIsolate, (
    RootIsolateToken.instance!,
    receivePort.sendPort,
  ));

  /// The first message sent from the isolate is the [SendPort] of the isolate.
  final sendPort = await receivePort.next<NamedSendPort>("setup");

  /// Next, a status code or an error is sent from the isolate.
  final status = await receivePort.next<Object>("setup");
  if (status case (final Object error, final StackTrace stackTrace)) {
    Error.throwWithStackTrace(error, stackTrace);
  }
  assert(status == 0, "The isolate should yield 0 after spawning properly.");

  final port = await receivePort.next<int>("setup");

  /// When everything is correct, we can create a [MessageChannel] to communicate with the isolate.
  final channel = MessageChannel(receivePort, sendPort);

  /// We create a dispose function to stop the isolate.
  ///   This allows us to not expose the isolate itself to the user.
  Future<void> dispose() async {
    final status = await channel.invoke("stop");
    switch (status) {
      case 0:
        if (kDebugMode) {
          print("Isolate stopped successfully.");
        }
        receivePort.close();
        isolate.kill(priority: Isolate.immediate);
        break;
      case _:
        if (kDebugMode) {
          print("Failed to stop the isolate.");
        }
        break;
    }
  }

  return ShelfServer(channel, port, dispose);
}
