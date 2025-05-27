import 'dart:async';

import 'package:easthardware_pms/backend/extensions/to_message_channel.dart';
import 'package:easthardware_pms/backend/utils/stream.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/try_future.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

Future<bool> httpPing(
  String address,
  int port,
) async {
  final pingUri = Uri.parse("http://$address:$port/ping");
  if (kDebugMode) {
    print("Connecting to $pingUri");
  }

  final (response, error) = await http.get(pingUri).tryCatch();
  if (error case (final Object error, final StackTrace stackTrace)) {
    if (kDebugMode) {
      print("Error connecting to $pingUri: $error");

      Error.throwWithStackTrace(error, stackTrace);
    }
    return false;
  }

  return true;
}

Future<(WebSocketChannel, MessageChannel, Stream<ServerEvent>)> connectToWebSocketServer(
  String address,
  int port,
  void Function() onConnectionClose,
) async {
  final uri = Uri.parse("ws://$address:$port");
  if (kDebugMode) {
    print("Connecting to $uri");
  }
  final webSocketChannel = WebSocketChannel.connect(uri);
  await webSocketChannel.ready;
  if (kDebugMode) {
    print("Connected to $uri");
  }

  final serverChannel = webSocketChannel.toMessageChannel(onConnectionClose);
  final status = await serverChannel.receivePort.next("status");
  if (kDebugMode) {
    print("Received status: $status");
  }

  final isSuccessful = status == 0;
  if (!isSuccessful) throw Error();

  final websocketStream = stream<ServerEvent>(() async* {
    while (serverChannel.isOpen) {
      final message = await serverChannel.receive("client");

      switch (message) {
        case ["didUpdate", final int msSinceEpoch]:
          // Notify the UI that the server has been updated.
          final dateTime = DateTime.fromMillisecondsSinceEpoch(msSinceEpoch);
          if (kDebugMode) {
            print("Server updated at: $dateTime");
          }

          yield ServerDatabaseUpdated(lastUpdated: dateTime);
          break;
        case _:
          if (kDebugMode) {
            print("Received unexpected message: $message");
          }
          break;
      }
    }
  });

  return (webSocketChannel, serverChannel, websocketStream);
}
