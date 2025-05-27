import 'dart:async';
import 'dart:io';

import 'package:easthardware_pms/backend/enum/database_mode.dart';
import 'package:easthardware_pms/backend/extension_types/shelf_server.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:easthardware_pms/presentation/bloc/server/services/server_connection_service.dart'
    as connection_service;
import 'package:easthardware_pms/presentation/bloc/server/services/server_preferences_service.dart'
    as server_preferences;
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/client_connection_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/server_configuration_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/server_mode_selection_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/server_success_dialogs.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'server_event.dart';
part 'server_state.dart';

/// This is the server bloc that handles the server state and events.
///   It is responsible for managing the server connection and
///   prompting the user for server/client information.
class ServerBloc extends Bloc<ServerEvent, ServerState> {
  ServerBloc(this.bottomTextNotifier) : super(const ServerState(status: ServerStatus.initial)) {
    /// Logic paths:
    ///   read the persisting data.
    ///   if no data is found, prompt the user for server/client information.
    ///     after the user selects a mode, prompt for server/client information.
    ///     if the user selects server, host the server.
    ///     if the user selects client, connect to the server.
    ///   if data is found, load the server/client information.
    on<ServerReset>(_onReset);
    on<ServerInit>(_onInit);
    on<ServerPromptingUserFromNull>(_onPromptingUserFromNull);

    on<ServerPromptingClientInformation>(_onPromptingClientInformation);
    on<ServerLoadingClientFromPreferences>(_onLoadingClientFromPreferences);

    on<ServerPromptingServerInformation>(_onPromptingServerInformation);
    on<ServerLoadingServerFromPreferences>(_onLoadingServerFromPreferences);

    on<ServerClientConnectionEstablished>(_onClientConnectionEstablished);
    on<ServerServerStarted>(_onServerStarted);

    on<ServerSaveClientInformation>(_saveClientInformation);
    on<ServerSaveServerInformation>(_saveServerInformation);

    on<ServerDatabaseUpdated>(_onDatabaseUpdated);
  }
  final ValueNotifier<String?> bottomTextNotifier;

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
      () => add(const ServerReset()),
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
    emit(const ServerState(status: ServerStatus.initial).copyWith(status: ServerStatus.loading));
    bottomTextNotifier.value = "Loading server data...";

    /// Load the server data from the root key.
    switch (await server_preferences.getSavedDatabaseMode()) {
      case null:
        bottomTextNotifier.value = "Found no saved data.";
        add(const ServerPromptingUserFromNull());

        return;
      case DatabaseMode.client:
        bottomTextNotifier.value = "Found existing client data.";

        final address = await server_preferences.getSavedServerAddress();

        if (address == null) {
          add(const ServerPromptingServerInformation());
        } else {
          add(ServerLoadingClientFromPreferences(
            address: address,
            popupToUser: true,
            saveToPreferences: true,
          ));
        }
      case DatabaseMode.server:
        final port = await server_preferences.getSavedServerPort();
        bottomTextNotifier.value = "Found existing server data. $port";

        if (port == null) {
          add(const ServerPromptingServerInformation());
        } else {
          add(ServerLoadingServerFromPreferences(port: port));
        }
    }
  }

  Future<void> _onPromptingUserFromNull(
    ServerPromptingUserFromNull event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(status: ServerStatus.promptingUser));

    switch (await ServerModeSelectionDialog.show(rootNavigatorKey.currentContext!)) {
      case _ when isClosed:
        return;
      case null:
        add(const ServerPromptingUserFromNull());
      case DatabaseMode.client:
        bottomTextNotifier.value = "Client mode selected.";
        emit(state.copyWith(status: ServerStatus.promptingClientInformation));
        add(const ServerPromptingClientInformation());
      case DatabaseMode.server:
        bottomTextNotifier.value = "Server mode selected.";
        emit(state.copyWith(status: ServerStatus.promptingServerInformation));
        add(const ServerPromptingServerInformation());
    }
  }

  Future<void> _onPromptingClientInformation(
    ServerPromptingClientInformation event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(
      status: ServerStatus.promptingClientInformation,
      databaseArgs: null,
      databaseHelper: null,
    ));
    final context = rootNavigatorKey.currentContext!;

    await ClientConnectionDialog.show(
      context: rootNavigatorKey.currentContext!,
      onCancel: () {
        Navigator.of(context).pop();

        add(const ServerPromptingUserFromNull());
      },
      onConfirm: (parentIp, port) async {
        Navigator.of(context).pop();

        add(
          ServerClientConnectionEstablished(
            saveToPreferences: true,
            popupToUser: true,
            args: ClientDatabaseArgs(
              parentIp: parentIp,
              port: port,
              webSocketChannel: null,
              messageChannel: null,
              close: null,
              stream: null,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onLoadingClientFromPreferences(
    ServerLoadingClientFromPreferences event,
    Emitter<ServerState> emit,
  ) async {
    throw UnimplementedError();

    try {
      emit(state.copyWith(
        status: ServerStatus.loadingClient,
        databaseArgs: null,
        databaseHelper: null,
      ));

      final serverAddress = event.address;
      final [serverIp, portString] = serverAddress.split(":");
      final port = int.parse(portString);
      final (webSocket, message, stream) = await _connectToServer(serverIp, port);

      add(
        ServerClientConnectionEstablished(
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
      add(const ServerPromptingClientInformation());
    }
  }

  Future<void> _onPromptingServerInformation(
    ServerPromptingServerInformation event,
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
        context: rootNavigatorKey.currentContext!,
        onStartServer: (port) => connection_service.startServers(port),
        onCancel: () => add(const ServerPromptingUserFromNull()),
        onSuccess: (landing, webSocket, stream) {
          add(ServerServerStarted(
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
      add(const ServerPromptingUserFromNull());
    }
  }

  Future<void> _onLoadingServerFromPreferences(
    ServerLoadingServerFromPreferences event,
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

      add(ServerServerStarted(
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

        add(ServerLoadingClientFromPreferences(
          address: '$localIp:$port',
          saveToPreferences: false,
          popupToUser: false,
        ));
      } else {
        add(const ServerPromptingServerInformation());
      }
    }
  }

  Future<void> _onClientConnectionEstablished(
    ServerClientConnectionEstablished event,
    Emitter<ServerState> emit,
  ) async {
    final address = '${event.args.parentIp}:${event.args.port}';
    bottomTextNotifier.value = "Connected to: $address";

    if (event.popupToUser) {
      final didUserCancelCompleter = Completer<bool>();
      ClientConnectionSuccessDialog.show(
        context: rootNavigatorKey.currentContext!,
        onCancel: () async {
          bottomTextNotifier.value = "Cancelled connection. Loading client data...";
          didUserCancelCompleter.complete(true);
          Navigator.of(rootNavigatorKey.currentContext!).pop();
          final args = state.databaseArgs as ClientDatabaseArgs;
          await args.close?.call();
          if (isClosed) return;

          add(const ServerPromptingClientInformation());
        },
        onConfirm: () {
          // Dialog will be dismissed automatically
          Navigator.of(rootNavigatorKey.currentContext!).pop();
          didUserCancelCompleter.complete(false);
        },
      );

      final didUserCancel = await didUserCancelCompleter.future;
      if (isClosed || didUserCancel) return;
    }

    /// If we confirmed, stream the events to this bloc.
    event.args.stream?.listen(add);

    /// Let the user know that we are connected.
    final channel = event.args.messageChannel!;
    emit(state.copyWith(
      status: ServerStatus.running,
      databaseArgs: event.args,
      databaseHelper: ServerDatabaseHelper(Server(channel)),
    ));
    if (event.saveToPreferences) {
      add(ServerSaveClientInformation(serverAddress: address));
    }
  }

  /// This runs whenever a server is started.
  Future<void> _onServerStarted(ServerServerStarted event, Emitter<ServerState> emit) async {
    final address = '${event.args.ip}:${event.args.port}';
    bottomTextNotifier.value = "Hosting at: $address";

    if (event.popupToUser) {
      final didUserCancelCompleter = Completer<bool>();
      ServerStartedSuccessDialog.show(
        context: rootNavigatorKey.currentContext!,
        serverIp: event.args.ip,
        port: event.args.port,
        onGoBack: () async {
          bottomTextNotifier.value = "Cancelled server. Loading server data...";
          didUserCancelCompleter.complete(true);
          Navigator.of(rootNavigatorKey.currentContext!).pop();
          if (isClosed) return;

          final args = event.args;
          await args.landingServer.close();
          await args.webSocketServer.close();
          if (isClosed) return;

          add(const ServerPromptingServerInformation());
        },
        onConfirm: () {
          Navigator.of(rootNavigatorKey.currentContext!).pop();
          didUserCancelCompleter.complete(false);
        },
      );

      final didUserCancel = await didUserCancelCompleter.future;
      if (isClosed || didUserCancel) return;
    }

    /// If we confirmed, start listening for events.
    event.args.stream.listen(add);

    /// We let the user know that the server is running.
    final channel = event.args.webSocketServer.channel;
    emit(state.copyWith(
      status: ServerStatus.running,
      databaseArgs: event.args,
      databaseHelper: ServerDatabaseHelper(Server(channel)),
    ));

    if (event.saveToPreferences) {
      add(ServerSaveServerInformation(port: event.args.port));
    }
  }

  Future<void> _saveClientInformation(
    ServerSaveClientInformation event,
    Emitter<ServerState> emit,
  ) async {
    await server_preferences.saveClientInformation(event.serverAddress);
  }

  Future<void> _saveServerInformation(
    ServerSaveServerInformation event,
    Emitter<ServerState> emit,
  ) async {
    await server_preferences.saveServerInformation(event.port);
  }

  Future<void> _onDatabaseUpdated(
    ServerDatabaseUpdated event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(lastUpdated: event.lastUpdated));
    bottomTextNotifier.value = "Server updated at: ${event.lastUpdated.toLocal()}";

    Future.delayed(const Duration(seconds: 2), () {
      if (isClosed) return;
      if (state.databaseArgs case ServerDatabaseArgs(:final ip, :final port)) {
        bottomTextNotifier.value = "Hosting at: $ip:$port";
      } else if (state.databaseArgs case ClientDatabaseArgs(:final parentIp, :final port)) {
        bottomTextNotifier.value = "Connected to: $parentIp:$port";
      }
    });
  }
}
