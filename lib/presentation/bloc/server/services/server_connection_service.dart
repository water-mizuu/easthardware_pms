import 'dart:io';

import 'package:easthardware_pms/domain/backend/extension_types/shelf_server.dart';
import 'package:easthardware_pms/domain/backend/server_host.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';

export 'package:easthardware_pms/domain/backend/server_connect.dart' show connectToWebSocketServer;

/// Starts the servers used in the application.
///   The first server is the landing Shelf server, which is exposed
///     to the public via the port specified in the `port` parameter.
///   The second server is the WebSocket server, which is used for real-time communication.
///     The port is not stable, and can only be accessed via the landing server.
Future<(ShelfServer, ShelfServer, Stream<ServerEvent>)> startServers(int port) async {
  return await hostShelfServer(port);
}

/// Gets the local WiFi IP address. If the device is not connected to WiFi,
/// it throws an exception with a descriptive message.
/// This is useful for displaying the server's address to the user.
/// The IP address is used to connect to the server from other devices on the same network.
Future<String> getLocalIpAddress() async {
  final localIp = await NetworkInfo().getWifiIP();
  if (localIp == null) {
    return "127.0.0.1";
  }
  return localIp;
}

/// Checks if a socket exception indicates the port is already in use
bool isPortAlreadyInUse(SocketException e) {
  return e.osError?.errorCode == 48;
}
