import 'package:easthardware_pms/backend/extensions/to_message_channel.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<(WebSocketChannel, MessageChannel)> connectToServer(
  String server,
  int port,
  void Function() onConnectionClose,
) async {
  final uri = Uri.parse("ws://$server:$port");
  if (kDebugMode) {
    print("Connecting to $uri");
  }
  final webSocketChannel = WebSocketChannel.connect(uri);
  await webSocketChannel.ready;
  if (kDebugMode) {
    print("Connected to $uri");
  }

  final serverChannel = webSocketChannel.toMessageChannel(onConnectionClose);
  final status = await serverChannel.receivePort.next("status");
  if (kDebugMode) {
    print("Received status: $status");
  }

  final isSuccessful = status == 0;
  if (!isSuccessful) throw Error();

  return (webSocketChannel, serverChannel);
}

Stream<ServerEvent> postConnectionSetup(MessageChannel channel) async* {
  while (!channel.receivePort.isClosed) {
    final message = await channel.receivePort.next("client");

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
}
