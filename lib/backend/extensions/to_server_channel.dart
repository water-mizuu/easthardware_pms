import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:easthardware_pms/utils/server_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

extension ServerChannelExtension on WebSocketChannel {
  ServerChannel toServerChannel({FutureOr<void> Function()? close}) {
    final receivePort = ReceivePort().hostListener();
    final sendPort = receivePort.sendPort;

    final internalReceivePort = ReceivePort()
      ..listen((object) {
        var result = jsonEncode(object);
        if (kDebugMode) {
          // print(["Sending to client", result]);
        }

        sink.add(result);
      });
    final internalSendPort = internalReceivePort.sendPort;

    stream.listen((m) {
      var result = jsonDecode(m);
      if (kDebugMode) {
        // print(["Received from client", result]);
      }

      sendPort.send(result);
    }, onDone: () async {
      await close?.call();
      internalReceivePort.close();
      receivePort.close();

      if (kDebugMode) {
        print("Closed connection to a client.");
      }
    });

    return ServerChannel(receivePort, internalSendPort);
  }
}
