/// A helper library that makes it easier to work with ReceivePorts and SendPorts.
///   It lets receive ports be used declaratively.
///   - For example, you can use the [next] method to get the next message from the receive port.
///   - You can also use the [call] method to get the next message from the receive port.
library;

import "dart:async";
import "dart:collection";
import "dart:isolate";

extension type ListenedReceivePort._(ReceivePort _port) {
  ListenedReceivePort(
    this._port,
    FutureOr<void> Function(Object? message)? fallbackListener,
  ) {
    _hosts[_port] = true;
    _isClosed = false;
    _completer = {};
    _queue = {};

    assert(!_port.isBroadcast, "The receive port must not be a broadcast stream.");

    _port.listen((payload) async {
      /// We add the message to the queue.
      final [name as String, message] = payload as List<Object?>;
      _queue[name] ??= Queue();
      _queue[name]!.addFirst(message);

      /// If there is a completer waiting for a message, we complete it.
      if (_completer[name] case final completer?) {
        completer.complete(message);
        _queue[name]!.removeLast();

        return;
      }
    });
  }

  /// This has the value of true for all ReceivePorts that can be listened to.
  ///   Since the ReceivePort is listened to, it can be used with the [next] extension method.
  ///   However, they cannot be listened to again.
  static final Expando<bool> _hosts = Expando();

  static final Expando<Map<String, Completer<Object?>>> _completers = Expando();
  static final Expando<Map<String, Queue<Object?>>> _queues = Expando();
  static final Expando<bool> _isCloseds = Expando();

  Map<String, Completer<Object?>> get _completer => _completers[_port]!;
  set _completer(Map<String, Completer<Object?>> completer) => _completers[_port] = completer;

  Map<String, Queue<Object?>> get _queue => _queues[_port]!;
  set _queue(Map<String, Queue<Object?>> queue) => _queues[_port] = queue;

  bool get _isClosed => _isCloseds[_port]!;
  set _isClosed(bool isClosed) => _isCloseds[_port] = isClosed;

  Future<T> next<T>(String name) async {
    if (_queue[name]?.isNotEmpty == true) {
      return _queue[name]!.removeFirst() as T;
    }

    final completer = Completer<void>();
    _completer[name] = completer;
    final rawValue = await completer.future as Object?;
    if (_completer[name] != completer) {
      completer.completeError(
        Exception("The completer for the name '$name' has been replaced."),
        StackTrace.current,
      );
      throw Error();
    }

    assert(
      rawValue is T,
      "The value received from the [ReceivePort] must be of type $T. "
      "Got ${rawValue.runtimeType} instead",
    );
    final value = rawValue as T;
    _completer.remove(name);

    return value;
  }

  /// Closes the [ReceivePort] and removes all the listeners.
  void close() {
    _hosts[_port] = null;
    _completers[_port] = null;
    _isCloseds[_port] = true;
    _port.close();
  }

  /// A [SendPort] which sends messages to this receive port.
  NamedSendPort get sendPort => NamedSendPort(_port.sendPort);

  bool get isClosed => _isClosed;
}

extension ReceivePortExtension on ReceivePort {
  ListenedReceivePort hostListener([FutureOr<void> Function(Object?)? fallbackListener]) =>
      ListenedReceivePort(this, fallbackListener);
}

extension type NamedSendPort(SendPort _port) implements SendPort {
  /// Sends a message to the send port.
  void send(String name, Object? message) {
    _port.send([name, message]);
  }
}
