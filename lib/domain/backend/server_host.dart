/// This library contains the code which hosts a shelf server(s)
///   through a background isolate.
library;

import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:easthardware_pms/domain/backend/microservices/key_microservice.dart' as keys_ms;
import 'package:easthardware_pms/domain/backend/server_host/landing_isolate.dart';
import 'package:easthardware_pms/domain/backend/server_host/web_socket_isolate.dart';
import 'package:easthardware_pms/domain/backend/utils/isolate_indicator.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:fluent_ui/fluent_ui.dart';
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

  final landingServer = await hostLandingServer(port);
  if (kDebugMode) {
    printBoxed("Hosting HTTP server on port ${landingServer.port}", "hostShelfServer");
  }

  final webSocketServer = await hostWebSocketServer();
  if (kDebugMode) {
    printBoxed("Hosting WebSocket server on port ${webSocketServer.port}", "hostShelfServer");
  }

  /// Handle calls from the landing isolate.
  /// @LANDING2MAIN:main
  final landingStream = landingServer.channel.listenStream<ServerEvent>(
    from: "main",
    (message) async* {
      final channel = landingServer.channel;
      if (kDebugMode) {
        printBoxed(message, "LANDING2MAIN:main");
      }

      if (message case [final String returnName, final Object request]) {
        switch (request) {
          case ['requestWsPort', _]:
            channel.send(to: returnName, webSocketServer.port);
            break;
          case ['requestKeys', _]:
            final requested = await keys_ms.keys;

            channel.send(to: returnName, requested);
            break;
          case _:
            if (kDebugMode) {
              printBoxed("Unknown request: $request", "LANDING2MAIN:main");
            }
            channel.send(to: returnName, -1); // Unknown request
            break;
        }
      }
    },
  );

  /// @WS2MAIN:main
  final webSocketStream = webSocketServer.channel.listenStream<ServerEvent>(
    from: "main",
    (message) async* {
      /// Handle calls from the webSocket isolate.
      final channel = webSocketServer.channel;
      if (kDebugMode) {
        printBoxed(message, "WS2MAIN:main");
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

              channel.send(to: returnName, secureConnection);
              break;
            case ['userLoggedIn', [final User user]]:
              channel.send(to: returnName, 0);
              if (kDebugMode) {
                printBoxed("User logged in: ${user.toMap()}");
              }
              final innerContext = overlayWidgetKey.currentContext;

              // Notify the app that a user has logged in.
              if (innerContext != null) {
                displayInfoBar(
                  innerContext,
                  builder: (context, close) {
                    return InfoBar(
                      title: const Text("User Logged In"),
                      content: Text("User ${user.username} has logged in."),
                      action: IconButton(
                        icon: const Icon(FluentIcons.clear),
                        onPressed: close,
                      ),
                      severity: InfoBarSeverity.success,
                    );
                  },
                );
              }

              break;
            case ['userLoggedOut', [final User user]]:
              channel.send(to: returnName, 0);
              if (kDebugMode) {
                printBoxed("User logged out: ${user.toMap()}");
              }
              final innerContext = overlayWidgetKey.currentContext;

              // Notify the app that a user has logged out.
              if (innerContext != null) {
                displayInfoBar(
                  innerContext,
                  builder: (context, close) {
                    return InfoBar(
                      title: const Text("User Logged Out"),
                      content: Text("User ${user.username} has logged out."),
                      action: IconButton(
                        icon: const Icon(FluentIcons.clear),
                        onPressed: close,
                      ),
                      severity: InfoBarSeverity.success,
                    );
                  },
                );
              }

              break;
            case _:
              if (kDebugMode) {
                printBoxed("Unknown request from $returnName: $request", "WS2MAIN:main");
              }
              channel.send(to: returnName, -1); // Unknown request
              break;
          }
          break;
      }
    },
  );

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
