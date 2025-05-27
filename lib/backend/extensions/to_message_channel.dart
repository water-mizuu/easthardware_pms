import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

extension MessageChannelExtension on WebSocketChannel {
  /// Creates a [MessageChannel] from an existing [WebSocketChannel].
  ///   This is useful as it automatically encodes and decodes messages to/from JSON.
  ///   The reason it does so is that [WebSocketChannel]s only support sending and receiving strings.
  MessageChannel toMessageChannel([void Function()? dispose]) {
    /// The [ReceivePort] is used to receive messages from the [WebSocketChannel].
    ///   We map each message through [jsonDecode], and send it to the sendPort.
    final receivePort = ReceivePort().hostListener();
    final sendPort = receivePort.sendPort;

    /// The internal receive port works as a mapper for the messages
    ///   into the webSocket channel. It encodes the messages to JSON string
    ///   and sends them to the webSocket channel.
    final internalReceivePort = ReceivePort()
      ..map(jsonEncode).listen((message) {
        if (kDebugMode) {
          final messageString = message.toString();
          final shortcut = messageString.substring(0, min(30, messageString.length));

          print("[WebSocketChannel] Sending message: $shortcut...");
        }
        // We send the message as a string to the WebSocketChannel.
        sink.add(message);
      });

    final internalSendPort = NamedSendPort(internalReceivePort.sendPort);
    final messageChannel = MessageChannel(receivePort, internalSendPort);

    void close() {
      if (kDebugMode) {
        print("[WebSocketChannel] Closing channel.");
      }
      internalReceivePort.close();
      receivePort.close();
      sink.close();
      dispose?.call();
    }

    stream.where((v) => v is String).cast<String>().map(jsonDecode).listen(
      (message) {
        if (kDebugMode) {
          final messageString = message.toString();
          final shortcut = messageString.substring(0, min(30, messageString.length));
          print("[WebSocketChannel] Received message: $shortcut...");
        }

        final [name as String, args] = message as List<Object?>;
        if (args case [final String id, ["ping", _]]) {
          messageChannel.sendPort.send(id, "pong");
        }

        sendPort.send(name, args);
      },
    );

    sink.done.whenComplete(() => close());

    return messageChannel;
  }
}
