part of 'server_bloc.dart';

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
  const ServerState({
    required this.status,
    this.databaseArgs,
    this.databaseHelper,
    this.lastUpdated,
  });

  final ServerStatus status;
  final DatabaseArgs? databaseArgs;
  final DatabaseHelper? databaseHelper;
  final DateTime? lastUpdated;

  ServerState Function({
    ServerStatus status,
    DatabaseArgs? databaseArgs,
    DatabaseHelper? databaseHelper,
    DateTime? lastUpdated,
  }) get copyWith {
    return ({
      Object? status = undefined,
      Object? databaseArgs = undefined,
      Object? databaseHelper = undefined,
      Object? lastUpdated = undefined,
    }) {
      return ServerState(
        status: status.or(this.status),
        databaseArgs: databaseArgs.or(this.databaseArgs),
        databaseHelper: databaseHelper.or(this.databaseHelper),
        lastUpdated: lastUpdated.or(this.lastUpdated),
      );
    };
  }

  @override
  get props => [status, databaseArgs, databaseHelper, lastUpdated];
}

sealed class DatabaseArgs {

  const DatabaseArgs(this.databaseMode);
  final DatabaseMode? databaseMode;
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
    required this.messageChannel,
    required this.close,
  }) : super(DatabaseMode.client);

  final String parentIp;
  final int port;
  final WebSocketChannel? webSocketChannel;
  final MessageChannel? messageChannel;
  final Future<void> Function() close;
}
