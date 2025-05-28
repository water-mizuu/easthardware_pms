import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:flutter/foundation.dart';

/// Represents a Shelf server with its associated [MessageChannel], port, and close function.
@immutable
extension type const ShelfServer._((MessageChannel, int, Future<void> Function()) _pair) {
  const ShelfServer(MessageChannel channel, int port, Future<void> Function() close)
      : _pair = (channel, port, close);

  /// The [MessageChannel] used to communicate with the server.
  MessageChannel get channel => _pair.$1;

  /// The port on which the server is hosted.
  int get port => _pair.$2;

  /// The function to close the server.
  Future<void> Function() get close => _pair.$3;
}
