import 'dart:async';
import 'dart:convert';

import 'package:easthardware_pms/backend/extensions/to_message_channel.dart';
import 'package:easthardware_pms/backend/secure_http.dart';
import 'package:easthardware_pms/backend/utils/stream.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/try_future.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<(WebSocketChannel, MessageChannel, Stream<ServerEvent>)> connectToWebSocketServer(
  String host,
  int port,
  void Function() onConnectionClose,
) async {
  final address = "$host:$port";
  final (result, error) = await _webSocketHandshake(address) //
      .tryCatch();

  if (error != null) {
    if (kDebugMode) {
      print("Failed to connect to WebSocket server at $address: $error");
    }
    throw Exception("Failed to connect to WebSocket server");
  }

  final (wsPort, sessionKey, encryptionKey, dispose) = result!.record;
  final websocketUri = Uri.parse("ws://$host:$wsPort?key=$sessionKey");
  if (kDebugMode) {
    print("Connecting to $websocketUri");
  }

  final webSocketChannel = WebSocketChannel.connect(websocketUri);
  await webSocketChannel.ready;
  if (kDebugMode) {
    print("Connected to $websocketUri");
  }

  final serverChannel = webSocketChannel.toEncryptedMessageChannel(
    encryptionKey,
    onConnectionClose,
  );

  final status = await serverChannel.receivePort.next("status");
  if (kDebugMode) {
    print("Received status: $status");
  }

  final isSuccessful = status == 0;
  if (!isSuccessful) throw Error();

  final websocketStream = stream<ServerEvent>(() async* {
    /// @LANDING2MAIN:client
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

Future<WebSocketHandshakeResult> _webSocketHandshake(String landingAddress) async {
  /// Requesting a websocket port requires a persistent
  ///   secure connection to the server, therefore we need to create
  ///   one beforehand.
  final target = Uri.parse("http://$landingAddress");
  final (sessionKey, encryptionKey, dispose) = await SecureHttp.pseudoTlsHandshake(
    target,
    isPersistent: true,
  );

  final websocketPortUri = Uri.parse("http://$landingAddress/request-ws-port?key=$sessionKey");
  final (websocketPortResponse, error1) = await SecureHttp.get(websocketPortUri).tryCatch();
  if (error1 != null) {
    if (kDebugMode) {
      print("Failed to get WebSocket port: $error1");
    }
    throw Exception("Failed to get WebSocket port");
  }

  if (jsonDecode(websocketPortResponse!.body) case {"port": final int wsPort}) {
    return WebSocketHandshakeResult(wsPort, sessionKey, encryptionKey, dispose);
  }

  if (kDebugMode) {
    printBoxed(websocketPortResponse.body, "Unknown response from WS port request");
  }
  throw Exception("Invalid response from WebSocket port request");
}

extension type const WebSocketHandshakeResult._(
    (
      int websocketPort,
      int sessionKey,
      BigInt encryptionKey,
      Future<void> Function() dispose,
    ) record) {
  const WebSocketHandshakeResult(
      int webSocketPort, int sessionKey, BigInt encryptionKey, Future<void> Function() dispose)
      : this._((webSocketPort, sessionKey, encryptionKey, dispose));

  int get websocketPort => record.$1;
  int get sessionKey => record.$2;
  BigInt get encryptionKey => record.$3;
  Future<void> Function() get dispose => record.$4;
}
