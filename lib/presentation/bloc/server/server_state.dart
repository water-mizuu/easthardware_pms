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
    this.customChannel,
    this.lastUpdated,
    this.bottomText,
    this.clientUserBeingLoggedOut,
  });

  final ServerStatus status;
  final DatabaseArgs? databaseArgs;
  final DatabaseHelper? databaseHelper;
  final WebSocketCustomChannel? customChannel;
  final DateTime? lastUpdated;
  final String? bottomText;
  final int? clientUserBeingLoggedOut;

  ServerState Function({
    ServerStatus status,
    DatabaseArgs? databaseArgs,
    DatabaseHelper? databaseHelper,
    WebSocketCustomChannel? customChannel,
    DateTime? lastUpdated,
    String bottomText,
    int? clientUserBeingLoggedOut,
  }) get copyWith {
    return ({
      Object? status = undefined,
      Object? databaseArgs = undefined,
      Object? databaseHelper = undefined,
      Object? customChannel = undefined,
      Object? lastUpdated = undefined,
      Object? bottomText = undefined,
      Object? clientUserBeingLoggedOut = undefined,
    }) {
      return ServerState(
        status: status.or(this.status),
        databaseArgs: databaseArgs.or(this.databaseArgs),
        databaseHelper: databaseHelper.or(this.databaseHelper),
        customChannel: customChannel.or(this.customChannel),
        lastUpdated: lastUpdated.or(this.lastUpdated),
        bottomText: bottomText.or(this.bottomText),
        clientUserBeingLoggedOut: clientUserBeingLoggedOut.or(this.clientUserBeingLoggedOut),
      );
    };
  }

  @override
  get props => [
        status,
        databaseArgs,
        databaseHelper,
        customChannel,
        lastUpdated,
        bottomText,
        clientUserBeingLoggedOut,
      ];
}

sealed class DatabaseArgs {
  const DatabaseArgs(this.databaseMode);
  final DatabaseMode databaseMode;
}

final class ServerDatabaseArgs extends DatabaseArgs {
  const ServerDatabaseArgs({
    required this.ip,
    required this.port,
    required this.landingServer,
    required this.webSocketServer,
    required this.stream,
  }) : super(DatabaseMode.server);

  final String ip;
  final int port;
  final ShelfServer landingServer;
  final ShelfServer webSocketServer;
  final Stream<ServerEvent> stream;
}

final class ClientDatabaseArgs extends DatabaseArgs {
  const ClientDatabaseArgs({
    required this.parentIp,
    required this.port,
    required this.webSocketChannel,
    required this.messageChannel,
    required this.close,
    required this.stream,
  }) : super(DatabaseMode.client);

  final String parentIp;
  final int port;
  final WebSocketChannel? webSocketChannel;
  final MessageChannel? messageChannel;
  final Future<void> Function()? close;
  final Stream<ServerEvent>? stream;
}
