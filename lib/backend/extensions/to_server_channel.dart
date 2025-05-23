import 'dart:convert';
import 'dart:isolate';

import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:easthardware_pms/utils/server_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

extension ServerChannelExtension on WebSocketChannel {
  /// Creates a [ServerChannel] from an existing [WebSocketChannel].
  ///   This is useful as it automatically encodes and decodes messages to/from JSON.
  ///   The reason it does so is that [WebSocketChannel]s only support sending and receiving strings.
  ServerChannel toServerChannel() {
    /// The [ReceivePort] is used to receive messages from the [WebSocketChannel].
    ///   We map each message through [jsonDecode], and send it to the sendPort.
    final receivePort = ReceivePort().hostListener();
    final sendPort = receivePort.sendPort;

    /// The internal receive port works as a mapper for the messages
    ///   into the websocket channel. It encodes the messages to JSON string
    ///   and sends them to the websocket channel.
    final internalReceivePort = ReceivePort()..map(jsonEncode).listen(sink.add);
    final internalSendPort = internalReceivePort.sendPort;

    stream.where((v) => v is String).cast<String>().map(jsonDecode).listen(
      sendPort.send,
      onDone: () async {
        internalReceivePort.close();
        receivePort.close();

        if (kDebugMode) {
          print("Closed connection to a client.");
        }
      },
    );

    return ServerChannel(receivePort, internalSendPort);
  }
}
