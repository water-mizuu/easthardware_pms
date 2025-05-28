import 'dart:async';
import 'dart:convert';

import 'package:easthardware_pms/backend/extensions/to_message_channel.dart';
import 'package:easthardware_pms/backend/secure_http.dart';
import 'package:easthardware_pms/backend/utils/stream.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/try_future.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

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
  final landingAddress = "$address:$port";
  final websocketPortUri = Uri.parse("http://$landingAddress/request-ws-port");
  final (websocketPortResponse, error1) = await SecureHttp.get(websocketPortUri).tryCatch();
  if (error1 != null) {
    if (kDebugMode) {
      print("Failed to get WebSocket port: $error1");
    }
    throw Exception("Failed to get WebSocket port");
  }

  final {"port": wsPort as int} = jsonDecode(websocketPortResponse!.body);

  if (kDebugMode) {
    print("WebSocket port for $landingAddress is $wsPort");
  }

  final websocketUri = Uri.parse("ws://$address:$wsPort");
  if (kDebugMode) {
    print("Connecting to $websocketUri");
  }
  final webSocketChannel = WebSocketChannel.connect(websocketUri);
  await webSocketChannel.ready;
  if (kDebugMode) {
    print("Connected to $websocketUri");
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
