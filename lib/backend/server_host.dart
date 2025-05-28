/// This library contains the code which hosts a shelf server(s)
///   through a background isolate.
library;

import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:easthardware_pms/backend/server_host/landing_isolate.dart';
import 'package:easthardware_pms/backend/server_host/web_socket_isolate.dart';
import 'package:easthardware_pms/backend/utils/isolate_indicator.dart';
import 'package:easthardware_pms/backend/utils/stream.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'extension_types/shelf_server.dart';

/// Hosts two shelf servers.
///   The HTTP Server, or the landing server, is hosted on the port.
///   The WebSocket Server, is dynamically hosted.
///
/// The [events] stream emits events related to the server status,
///   resulted from the listening loop of the isolate.
Future<(ShelfServer, ShelfServer, Stream<ServerEvent>)> hostShelfServer(int port) async {
  assertMainIsolate();
  //
  final landingServer = await hostLandingServer(port);
  final webSocketServer = await hostWebSocketServer();

  /// Handle calls from the landing isolate.
  final landingStream = stream<ServerEvent>(() async* {
    final channel = landingServer.channel;
    while (channel.isOpen) {
      final message = await channel.receive('main');
      if (kDebugMode) {
        print("*" * 20);
        print("[LANDING@MAIN] Received message: $message");
        print("*" * 20);
      }

      if (message case [final String returnName, final Object request]) {
        switch (request) {
          case ['requestWsPort', _]:
            channel.send(returnName, webSocketServer.port);
            break;
        }
      }
    }
  });

  /// Handle calls from the webSocket isolate.
  final webSocketStream = stream<ServerEvent>(() async* {
    final channel = webSocketServer.channel;
    while (channel.isOpen) {
      final message = await channel.receive('main');
      if (kDebugMode) {
        print("*" * 20);
        print("[WEB_SOCKET@MAIN] Received message: $message");
        print("*" * 20);
      }

      switch (message) {
        case ['didUpdate', final int msSinceEpoch]:
          final dateTime = DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
          if (kDebugMode) {
            print("Server updated at: $dateTime");
          }
          yield ServerDatabaseUpdated(lastUpdated: dateTime);
          break;
        case [final String returnName, final Object request]:
          switch (request) {
            case ['requestConnection', [final int sessionKey]]:
              final secureConnection = await landingServer.channel.invoke(
                "requestConnection",
                [sessionKey],
              );

              channel.send(returnName, secureConnection);
              break;
          }
          break;
      }
    }
  });

  /// Merge the streams into one.
  final fullStream = StreamGroup.merge([landingStream, webSocketStream]);

  return (landingServer, webSocketServer, fullStream);
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
