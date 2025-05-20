import 'dart:isolate';

import 'parallelism.dart';

class ServerChannel {
  final ListenedReceivePort receivePort;
  final SendPort sendPort;

  ServerChannel(this.receivePort, this.sendPort);

  Future<Object?> invoke(String method, [List<Object?>? arguments]) {
    sendPort.send([method, arguments]);
    return receivePort.next();
  }
}
