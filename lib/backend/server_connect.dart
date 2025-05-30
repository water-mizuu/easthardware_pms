import 'dart:async';
import 'dart:convert';

import 'package:easthardware_pms/backend/extension_types/secure_keys.dart';
import 'package:easthardware_pms/backend/extensions/to_message_channel.dart';
import 'package:easthardware_pms/backend/secure_http.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/try_future.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<(WebSocketChannel, MessageChannel, Stream<ServerEvent>)> connectToWebSocketServer(
  String host,
  int port, {
  required void Function() onConnectionClose,
}) async {
  if (kDebugMode) {
    printBoxed(
      "Connecting to server at $host:$port",
      "connectToWebSocketServer",
    );
  }

  final address = "$host:$port";
  final (result, error) = await _webSocketHandshake(address).tryCatch();
  if (error != null) {
    if (kDebugMode) {
      print("Failed to connect to WebSocket server at $address: $error");
    }
    throw Exception("Failed to connect to WebSocket server");
  }

  final (wsPort, sessionKey, encryptionKey, dispose) = result!.record;
  if (kDebugMode) {
    printBoxed(
      "Successfully negotiated persistent secure connection to WebSocket server at $address \n"
          "  with session key: $sessionKey and encryption key: $encryptionKey",
      "connectToWebSocketServer",
    );
  }

  final websocketUri = Uri.parse("ws://$host:$wsPort?key=$sessionKey");
  final webSocketChannel = WebSocketChannel.connect(websocketUri);
  final (_, error2) = await webSocketChannel.ready.tryCatch();
  if (error2 != null) {
    if (kDebugMode) {
      print("Failed to establish WebSocket connection: $error2");
    }
    await dispose();
    throw Exception("Failed to establish WebSocket connection");
  }
  if (kDebugMode) {
    printBoxed(
      "Successfully connected to WebSocket server at $websocketUri",
      "connectToWebSocketServer",
    );
  }

  final serverChannel = webSocketChannel.toEncryptedMessageChannel(
    encryptionKey,
    onConnectionClose,
  );

  final (status, error3) = await serverChannel.receive(from: "status").tryCatch();
  if (error3 != null) {
    if (kDebugMode) {
      print("Failed to receive status from server: $error3");
    }
    await dispose();
    throw Exception("Failed to receive status from server");
  }
  if (kDebugMode) {
    printBoxed(
      "Received status code from WebSocket server: $status",
      "connectToWebSocketServer",
    );
  }

  final isSuccessful = status == 0;
  if (!isSuccessful) throw Error();

  /// @LANDING2MAIN:client
  final websocketStream = serverChannel.listenStream(
    from: "client",
    (message) async* {
      if (kDebugMode) {
        printBoxed(message, "LANDING2MAIN:client");
      }

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
    },
  );

  return (webSocketChannel, serverChannel, websocketStream);
}

/// Manages establishing a WebSocket connection with the server.
Future<_WebSocketHandshakeResult> _webSocketHandshake(String landingAddress) async {
  /// Requesting a websocket port requires a persistent
  ///   secure connection to the server, therefore we need to create
  ///   one beforehand.
  final target = Uri.parse("http://$landingAddress");
  final (:sessionKey, :encryptionKey, :dispose) = await SecureHttp.pseudoTlsHandshake(
    target,
    isPersistent: true,
  );

  /// After we get a secure connection, we can request the WebSocket port.
  final websocketPortUri = Uri.parse("http://$landingAddress/request-ws-port?key=$sessionKey");
  final (websocketPortResponse, error1) = await SecureHttp.get(websocketPortUri).tryCatch();
  if (error1 != null) {
    if (kDebugMode) {
      print("Failed to get WebSocket port: $error1");
    }
    throw Exception("Failed to get WebSocket port");
  }

  /// SUCCESS CONDITION:
  ///  The response should be a JSON object with a "port" field.
  if (jsonDecode(websocketPortResponse!.body) case {"port": final int wsPort}) {
    return _WebSocketHandshakeResult(wsPort, sessionKey, encryptionKey, dispose);
  }

  if (kDebugMode) {
    printBoxed(websocketPortResponse.body, "Unknown response from WS port request");
  }
  throw Exception("Invalid response from WebSocket port request");
}

extension type const _WebSocketHandshakeResult._(
    (int, SessionKey, EncryptionKey, Future<void> Function()) record) {
  const _WebSocketHandshakeResult(int webSocketPort, SessionKey sessionKey,
      EncryptionKey encryptionKey, Future<void> Function() dispose)
      : this._((webSocketPort, sessionKey, encryptionKey, dispose));

  int get websocketPort => record.$1;
  SessionKey get sessionKey => record.$2;
  EncryptionKey get encryptionKey => record.$3;
  Future<void> Function() get dispose => record.$4;
}
