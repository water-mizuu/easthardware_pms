import 'dart:async';
import 'dart:io';

import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:easthardware_pms/domain/backend/enum/database_mode.dart';
import 'package:easthardware_pms/domain/backend/extension_types/shelf_server.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/security_question.dart';
import 'package:easthardware_pms/mock_data_implementation_full.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/server/services/server_connection_service.dart'
    as connection_service;
import 'package:easthardware_pms/presentation/bloc/server/services/server_preferences_service.dart'
    as server_preferences;
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/client_connection_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/server_configuration_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/server_mode_selection_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/server_success_dialogs.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'server_event.dart';
part 'server_state.dart';

/// This is the server bloc that handles the server state and events.
///   It is responsible for managing the server connection and
///   prompting the user for server/client information.
class ServerBloc extends Bloc<ServerEvent, ServerState> {
  ServerBloc() : super(const ServerState(status: ServerStatus.initial)) {
    /// Logic paths:
    ///   read the persisting data.
    ///   if no data is found, prompt the user for server/client information.
    ///     after the user selects a mode, prompt for server/client information.
    ///     if the user selects server, host the server.
    ///     if the user selects client, connect to the server.
    ///   if data is found, load the server/client information.
    on<ServerReset>(_onReset);
    on<ServerInit>(_onInit);
    on<_ServerPromptingUserFromNull>(_onPromptingUserFromNull);

    on<_ServerPromptingClientInformation>(_onPromptingClientInformation);
    on<_ServerLoadingClientFromPreferences>(_onLoadingClientFromPreferences);

    on<_ServerPromptingServerInformation>(_onPromptingServerInformation);
    on<_ServerLoadingServerFromPreferences>(_onLoadingServerFromPreferences);

    on<_ServerClientConnectionEstablished>(_onClientConnectionEstablished);
    on<_ServerServerStarted>(_onServerStarted);

    on<_ServerSaveClientInformation>(_saveClientInformation);
    on<_ServerSaveServerInformation>(_saveServerInformation);

    on<ServerDatabaseUpdated>(_onDatabaseUpdated);
    on<_ServerResetBottomText>(_onResetBottomText);

    if (kDebugMode) {
      on<ServerDatabaseCleared>(_onServerDatabaseCleared);
      on<ServerMockDataAdded>(_onServerMockDataAdded);
    }
  }

  @override
  void onEvent(ServerEvent event) {
    if (kDebugMode) {
      print("[SERVER_BLOC] ${event.runtimeType}");
    }

    super.onEvent(event);
  }

  /// A helper method that connects to the server. It indicates that whenever the connection
  ///   is disposed, the server is reset.
  Future<(WebSocketChannel, MessageChannel, Stream<ServerEvent>)> _connectToServer(
    String serverIp,
    int port,
  ) async {
    return await connection_service.connectToWebSocketServer(
      serverIp,
      port,
      onConnectionClose: () {
        final innerContext = rootWidgetKey.currentContext;
        if (innerContext == null || !innerContext.mounted) return;
        if (kDebugMode) {
          printBoxed(
            "Connection to server at $serverIp:$port closed.",
            "ServerBloc",
          );
        }

        /// If the connection is closed, we reset the server state.
        ///   We also reset the authentication bloc.

        final authenticationBloc = innerContext.read<AuthenticationBloc>();
        if (authenticationBloc.state.user != null) {
          authenticationBloc.add(const AuthenticationLogoutEvent());
        }

        add(const ServerReset());
      },
    );
  }

  Future<void> _onReset(ServerReset event, Emitter<ServerState> emit) async {
    await server_preferences.resetSharedPreferences();

    add(const ServerInit());
  }

  Future<void> _onInit(ServerInit event, Emitter<ServerState> emit) async {
    /// Close any server or client connections that are open.
    if (state.databaseArgs case final ServerDatabaseArgs args) {
      await args.landingServer.close();
      await args.webSocketServer.close();
    } else if (state.databaseArgs case ClientDatabaseArgs(:final close?)) {
      await close();
    }

    /// Reset the state to initial.
    emit(const ServerState(status: ServerStatus.initial)
        .copyWith(status: ServerStatus.loading, bottomText: "Loading server data..."));

    /// Load the server data from the root key.
    switch (await server_preferences.getSavedDatabaseMode()) {
      case null:
        emit(state.copyWith(bottomText: "No saved data found. Prompting user..."));
        add(const _ServerPromptingUserFromNull());

        return;
      case DatabaseMode.client:
        emit(state.copyWith(bottomText: "Found existing client data."));

        final address = await server_preferences.getSavedServerAddress();
        if (address == null) {
          add(const _ServerPromptingServerInformation());
        } else {
          add(_ServerLoadingClientFromPreferences(
            address: address,
            popupToUser: true,
            saveToPreferences: true,
          ));
        }
      case DatabaseMode.server:
        final port = await server_preferences.getSavedServerPort();
        emit(state.copyWith(bottomText: "Found existing server data. $port"));

        if (port == null) {
          add(const _ServerPromptingServerInformation());
        } else {
          add(_ServerLoadingServerFromPreferences(port: port));
        }
    }
  }

  Future<void> _onPromptingUserFromNull(
    _ServerPromptingUserFromNull event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(status: ServerStatus.promptingUser));

    switch (await ServerModeSelectionDialog.show(rootWidgetKey.currentContext!)) {
      case _ when isClosed:
        return;
      case null:
        add(const _ServerPromptingUserFromNull());
      case DatabaseMode.client:
        emit(state.copyWith(
          status: ServerStatus.promptingClientInformation,
          bottomText: "Prompting for client information...",
        ));
        add(const _ServerPromptingClientInformation());
      case DatabaseMode.server:
        emit(state.copyWith(
          status: ServerStatus.promptingServerInformation,
          bottomText: "Server mode selected.",
        ));
        add(const _ServerPromptingServerInformation());
    }
  }

  Future<void> _onPromptingClientInformation(
    _ServerPromptingClientInformation event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(
      status: ServerStatus.promptingClientInformation,
      databaseArgs: null,
      databaseHelper: null,
    ));
    final context = rootWidgetKey.currentContext!;

    await ClientConnectionDialog.show(
      onConnectToServer: _connectToServer,
      onCancel: () {
        Navigator.of(context).pop();

        add(const _ServerPromptingUserFromNull());
      },
      onConfirm: (messageChannel, databaseArgs) async {
        Navigator.of(context).pop();

        add(
          _ServerClientConnectionEstablished(
            saveToPreferences: true,
            popupToUser: true,
            args: databaseArgs,
          ),
        );
      },
    );
  }

  Future<void> _onLoadingClientFromPreferences(
    _ServerLoadingClientFromPreferences event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(
      status: ServerStatus.loadingClient,
      databaseArgs: null,
      databaseHelper: null,
    ));

    try {
      final serverAddress = event.address;
      final [serverIp, portString] = serverAddress.split(":");
      final port = int.parse(portString);
      final (webSocket, message, stream) = await _connectToServer(serverIp, port);

      add(
        _ServerClientConnectionEstablished(
          saveToPreferences: event.saveToPreferences,
          popupToUser: false,
          args: ClientDatabaseArgs(
            parentIp: serverIp,
            port: port,
            webSocketChannel: webSocket,
            messageChannel: message,
            close: () async {
              await webSocket.sink.close();
            },
            stream: stream,
          ),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      if (kDebugMode) {
        print(e);
      }
      add(const _ServerPromptingClientInformation());
    }
  }

  Future<void> _onPromptingServerInformation(
    _ServerPromptingServerInformation event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(
      status: ServerStatus.promptingServerInformation,
      databaseArgs: null,
      databaseHelper: null,
    ));

    try {
      final localIp = await connection_service.getLocalIpAddress();
      if (isClosed) return;

      await ServerConfigurationDialog.show(
        onStartServer: (port) => connection_service.startServers(port),
        onCancel: () => add(const _ServerPromptingUserFromNull()),
        onSuccess: (landing, webSocket, stream) {
          add(_ServerServerStarted(
            saveToPreferences: true,
            popupToUser: true,
            args: ServerDatabaseArgs(
              ip: localIp,
              port: landing.port,
              landingServer: landing,
              webSocketServer: webSocket,
              stream: stream,
            ),
          ));
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local IP or showing dialog: $e');
      }
      add(const _ServerPromptingUserFromNull());
    }
  }

  Future<void> _onLoadingServerFromPreferences(
    _ServerLoadingServerFromPreferences event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(
      status: ServerStatus.loadingServer,
      databaseArgs: null,
      databaseHelper: null,
    ));

    final port = event.port;
    final localIp = await NetworkInfo().getWifiIP().then((p) => p!);
    if (isClosed) return;
    try {
      final (landing, webSocket, stream) = await connection_service.startServers(port);
      if (isClosed) return;

      add(_ServerServerStarted(
        saveToPreferences: event.saveToPreferences,
        popupToUser: false,
        args: ServerDatabaseArgs(
          ip: localIp,
          port: port,
          landingServer: landing,
          webSocketServer: webSocket,
          stream: stream,
        ),
      ));
    } on SocketException catch (e) {
      if (e.osError case OSError(errorCode: 48)) {
        /// If the port is already in use, we can either:
        ///   Connect to the existing server already running on that port.
        if (kDebugMode) {
          print("Port is already in use. Trying to connect to it.");
        }

        add(_ServerLoadingClientFromPreferences(
          address: '$localIp:$port',
          saveToPreferences: false,
          popupToUser: false,
        ));
      } else {
        add(const _ServerPromptingServerInformation());
      }
    }
  }

  Future<void> _onClientConnectionEstablished(
    _ServerClientConnectionEstablished event,
    Emitter<ServerState> emit,
  ) async {
    final address = '${event.args.parentIp}:${event.args.port}';
    emit(state.copyWith(bottomText: "Connected to: $address"));
    await Future.delayed(Duration.zero);
    if (isClosed) return;

    /// If we confirmed, stream the events to this bloc.
    event.args.stream?.listen(add);

    /// Let the user know that we are connected.
    emit(state.copyWith(
      status: ServerStatus.running,
      databaseArgs: event.args,
      databaseHelper: ServerDatabaseHelper(Server(event.args.messageChannel!)),
      customChannel: WebSocketCustomChannel(event.args.messageChannel!),
    ));

    if (event.popupToUser) {
      final didUserCancelCompleter = Completer<bool>();

      await ClientConnectionSuccessDialog.show(
        context: rootWidgetKey.currentContext!,
        onCancel: () async {
          if (isClosed) return;
          emit(state.copyWith(bottomText: "Cancelled connection. Loading client data..."));
          didUserCancelCompleter.complete(true);
          Navigator.of(rootWidgetKey.currentContext!).pop();
          final args = state.databaseArgs as ClientDatabaseArgs;
          await args.close?.call();
          if (isClosed) return;

          add(const _ServerPromptingClientInformation());
        },
        onConfirm: () {
          // Dialog will be dismissed automatically
          Navigator.of(rootWidgetKey.currentContext!).pop();
          didUserCancelCompleter.complete(false);
        },
      );

      final didUserCancel = await didUserCancelCompleter.future;
      if (isClosed || didUserCancel) return;
    }

    if (event.saveToPreferences) {
      add(_ServerSaveClientInformation(serverAddress: address));
    }
  }

  /// This runs whenever a server is started.
  Future<void> _onServerStarted(_ServerServerStarted event, Emitter<ServerState> emit) async {
    final address = '${event.args.ip}:${event.args.port}';
    emit(state.copyWith(bottomText: "Hosting at: $address"));
    await Future.delayed(Duration.zero);
    if (isClosed) return;

    /// If we confirmed, start listening for events.
    event.args.stream.listen(add);

    /// We let the user know that the server is running.
    final channel = event.args.webSocketServer.channel;
    emit(state.copyWith(
      status: ServerStatus.running,
      databaseArgs: event.args,
      databaseHelper: ServerDatabaseHelper(Server(channel)),
      customChannel: WebSocketCustomChannel(channel),
    ));

    if (event.popupToUser) {
      final didUserCancelCompleter = Completer<bool>();
      await ServerStartedSuccessDialog.show(
        serverIp: event.args.ip,
        port: event.args.port,
        onGoBack: () async {
          emit(state.copyWith(bottomText: "Cancelled server. Loading server data..."));
          didUserCancelCompleter.complete(true);
          Navigator.of(rootWidgetKey.currentContext!).pop();
          if (isClosed) return;

          final args = event.args;
          await args.landingServer.close();
          await args.webSocketServer.close();
          if (isClosed) return;

          add(const _ServerPromptingServerInformation());
        },
        onConfirm: () {
          Navigator.of(rootWidgetKey.currentContext!).pop();
          didUserCancelCompleter.complete(false);
        },
      );

      final didUserCancel = await didUserCancelCompleter.future;
      if (isClosed || didUserCancel) return;
    }

    if (event.saveToPreferences) {
      add(_ServerSaveServerInformation(port: event.args.port));
    }
  }

  Future<void> _saveClientInformation(
    _ServerSaveClientInformation event,
    Emitter<ServerState> emit,
  ) async {
    await server_preferences.saveClientInformation(event.serverAddress);
  }

  Future<void> _saveServerInformation(
    _ServerSaveServerInformation event,
    Emitter<ServerState> emit,
  ) async {
    await server_preferences.saveServerInformation(event.port);
  }

  Future<void> _onDatabaseUpdated(
    ServerDatabaseUpdated event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(
      lastUpdated: event.lastUpdated,
      bottomText: "Server updated at: ${event.lastUpdated.toLocal()}",
    ));

    Future.delayed(const Duration(seconds: 2), () {
      add(const _ServerResetBottomText());
    });
  }

  Future<void> _onResetBottomText(_ServerResetBottomText event, Emitter<ServerState> emit) async {
    if (state.databaseArgs case ServerDatabaseArgs(:final ip, :final port)) {
      emit(state.copyWith(
        bottomText: "Hosting at: $ip:$port",
      ));
    } else if (state.databaseArgs case ClientDatabaseArgs(:final parentIp, :final port)) {
      emit(state.copyWith(
        bottomText: "Connected to: $parentIp:$port",
      ));
    }
  }

  Future<void> _onServerDatabaseCleared(
    ServerDatabaseCleared event,
    Emitter<ServerState> emit,
  ) async {
    if (kDebugMode) {
      final databaseHelper = state.databaseHelper;
      if (databaseHelper == null) {
        print("Database helper is null, cannot clear database");
        showNotification(
          title: "Error",
          message: "Database helper is null",
          severity: InfoBarSeverity.error,
        );
        return;
      }

      if (databaseHelper.database case final ResettableDatabase database) {
        await database.reset();
        if (isClosed) return;

        add(ServerDatabaseUpdated(lastUpdated: DateTime.now()));
      }
    }
  }

  Future<void> _onServerMockDataAdded(
    ServerMockDataAdded event,
    Emitter<ServerState> emit,
  ) async {
    if (kDebugMode) {
      final databaseHelper = state.databaseHelper;
      await generateMockData(databaseHelper!);

      if (isClosed) return;
      add(ServerDatabaseUpdated(lastUpdated: DateTime.now()));
    }
  }
}

typedef MockUser = ({
  String firstName,
  String lastName,
  AccessLevel accessLevel,
  List<SecurityQuestion> securityQuestions,
});
