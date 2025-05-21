import 'package:easthardware_pms/app/app.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/utils/server_channel.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ServerStatus {
  initial,
  loading,
  promptingUser,
  loadingClient,
  promptingClientInformation,
  loadingServer,
  promptingServerInformation,
  running,
  closing,
}

@immutable
class ServerState with EquatableMixin {
  const ServerState({required this.status, this.databaseArgs, this.databaseHelper});

  final ServerStatus status;
  final DatabaseArgs? databaseArgs;
  final DatabaseHelper? databaseHelper;

  ServerState copyWith({
    ServerStatus? status,
    DatabaseArgs? databaseArgs,
    DatabaseHelper? databaseHelper,
  }) {
    return ServerState(
      status: status ?? this.status,
      databaseArgs: databaseArgs ?? this.databaseArgs,
      databaseHelper: databaseHelper ?? this.databaseHelper,
    );
  }

  @override
  get props => [status, databaseArgs, databaseHelper];
}

sealed class DatabaseArgs {
  final DatabaseMode? databaseMode;

  const DatabaseArgs(this.databaseMode);
}

final class ServerDatabaseArgs extends DatabaseArgs {
  const ServerDatabaseArgs({
    required this.ip,
    required this.port,
    required this.close,
  }) : super(DatabaseMode.server);

  final String ip;
  final int port;
  final Future<void> Function() close;
}

final class ClientDatabaseArgs extends DatabaseArgs {
  const ClientDatabaseArgs({
    required this.parentIp,
    required this.port,
    required this.webSocketChannel,
    required this.serverChannel,
    required this.close,
  }) : super(DatabaseMode.client);

  final String parentIp;
  final int port;
  final WebSocketChannel? webSocketChannel;
  final ServerChannel? serverChannel;
  final Future<void> Function() close;
}
