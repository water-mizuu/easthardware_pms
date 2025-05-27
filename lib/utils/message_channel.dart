import 'package:uuid/uuid.dart';

import 'parallelism.dart';

/// A message channel is a half duplex communication channel
///   which can be used to send messages between isolates,
///   or with extra setup, between a client and a server.
extension type const MessageChannel._((ListenedReceivePort, NamedSendPort) pair) {
  const MessageChannel(ListenedReceivePort receivePort, NamedSendPort sendPort)
      : pair = (receivePort, sendPort);

  ListenedReceivePort get receivePort => pair.$1;
  NamedSendPort get sendPort => pair.$2;

  bool get isClosed => receivePort.isClosed;
  bool get isOpen => !receivePort.isClosed;

  /// Invokes a method on the channel with the given arguments.
  /// Returns a future which completes with the result of the invocation.
  Future<T> invoke<T>(String method, [List<Object?>? arguments]) {
    final name = const Uuid().v4();
    final payload = [method, arguments];

    /// We send an invocation request, alongside the completer name and the payload.
    /// The completer name is used to identify the response.
    sendPort.send("invocation", [name, payload]);

    return receivePort.next(name);
  }
}
