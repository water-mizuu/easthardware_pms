import 'dart:async';
import 'dart:isolate';

import 'package:easthardware_pms/backend/utils/random_int_from_date.dart';
import 'package:easthardware_pms/backend/utils/stream.dart';

import 'parallelism.dart';

/// A message channel is a half duplex communication channel which can be used
///   to send messages between isolates, or with extra setup, between a client and a server.
/// The creator of the channel is responsible for closing the [ReceivePort].
///   Essentially, this is a wrapper around a [ReceivePort] and a [NamedSendPort].
///   If you want to create a channel which can be closed and disposed of after use,
///   use [DisposableMessageChannel].
extension type const MessageChannel._((ListenedReceivePort, NamedSendPort) pair) {
  const MessageChannel(ListenedReceivePort receivePort, NamedSendPort sendPort)
      : pair = (receivePort, sendPort);

  ListenedReceivePort get receivePort => pair.$1;
  NamedSendPort get sendPort => pair.$2;

  bool get isClosed => receivePort.isClosed;
  bool get isOpen => !receivePort.isClosed;

  /// Invokes a method on a specified channel with the given arguments.
  /// Returns a future which completes with the result of the invocation.
  Future<T> invokeNamed<T>(String name, String method, [List<Object?>? arguments]) {
    final uuid = randomIntFromDate().toString();
    final payload = [method, arguments];

    /// We send an invocation request, alongside the completer name and the payload.
    /// The completer name is used to identify the response.
    sendPort.send(name, [uuid, payload]);

    return receivePort.next(uuid);
  }

  /// Invokes a method on the channel with the given arguments.
  /// Returns a future which completes with the result of the invocation.
  Future<T> invoke<T>(String method, [List<Object?>? arguments]) =>
      invokeNamed("invocation", method, arguments);

  Future<T> receive<T>({required String from}) => receivePort.next(from);
  void send(Object? message, {required String to}) => sendPort.send(to, message);

  /// Creates a listener for messages on the specified channel.
  ///   The listener will call the provided [onMessage] function
  void listenFrom(
    String name,
    FutureOr<void> Function(Object? message) onMessage, {
    void Function()? onDone,
  }) {
    unawaited(() async {
      while (!receivePort.isClosed) {
        final message = await receivePort.next(name);

        onMessage(message);
      }

      onDone?.call();
    }());
  }

  /// Listens to messages on the specific channel, allowing the user to
  ///   yield a stream of objects based on the received messages.
  Stream<T> listenStream<T>(
    Stream<T> Function(Object? message) onMessage, {
    required String from,
    void Function()? onDone,
  }) {
    return stream<T>(() async* {
      while (!receivePort.isClosed) {
        final message = await receivePort.next(from);

        yield* onMessage(message);
      }

      onDone?.call();
    });
  }
}

/// A disposable message channel is a message channel which can be closed
///   and disposed of after use. This is different from a regular message channel
///   such that it is responsible for closing its receive port when it is no longer needed.
extension type const DisposableMessageChannel._(MessageChannel channel) implements MessageChannel {
  DisposableMessageChannel(NamedSendPort sendPort)
      : this._(MessageChannel(ReceivePort().hostListener(), sendPort));

  ListenedReceivePort get receivePort => channel.receivePort;
  NamedSendPort get sendPort => channel.sendPort;

  bool get isClosed => channel.isClosed;
  bool get isOpen => !channel.isClosed;

  Future<T> invokeNamed<T>(String name, String method, [List<Object?>? arguments]) =>
      channel.invokeNamed(name, method, arguments);

  Future<T> invoke<T>(String method, [List<Object?>? arguments]) =>
      channel.invoke(method, arguments);

  Future<T> receive<T>({required String from}) => channel.receive(from: from);
  void send(Object? message, {required String to}) => channel.send(message, to: to);

  /// Closes the message channel and its receive port.
  void close() {
    if (isOpen) {
      receivePort.close();
    }
  }
}
