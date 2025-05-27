import 'dart:io';

import 'package:easthardware_pms/backend/extension_types/shelf_server.dart';
import 'package:easthardware_pms/backend/server_host.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';

export 'package:easthardware_pms/backend/server_connect.dart' show connectToWebSocketServer;

/// Starts a server on the given port
Future<(ShelfServer, ShelfServer, Stream<ServerEvent>)> startServers(int port) async {
  return await hostShelfServer(port);
}

/// Gets the local WiFi IP address
Future<String> getLocalIpAddress() async {
  final localIp = await NetworkInfo().getWifiIP();
  if (localIp == null) {
    throw Exception('Could not determine local IP address');
  }
  return localIp;
}

/// Checks if a socket exception indicates the port is already in use
bool isPortAlreadyInUse(SocketException e) {
  return e.osError?.errorCode == 48;
}
