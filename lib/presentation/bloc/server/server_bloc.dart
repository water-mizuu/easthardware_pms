import 'dart:async';
import 'dart:io';

import 'package:easthardware_pms/backend/enum/database_mode.dart';
import 'package:easthardware_pms/backend/server_connect.dart';
import 'package:easthardware_pms/backend/server_host.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_event.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_state.dart';
import 'package:easthardware_pms/presentation/bloc/server/services/server_connection_service.dart'
    as connection_service;
import 'package:easthardware_pms/presentation/bloc/server/services/server_preferences_service.dart'
    as server_preferences;
import 'package:easthardware_pms/presentation/widgets/server/client_connection_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/server/server_configuration_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/server/server_mode_selection_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/server/server_success_dialogs.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

export 'server_event.dart';
export 'server_state.dart';

/// This is the server bloc that handles the server state and events.
///   It is responsible for managing the server connection and
///   prompting the user for server/client information.
class ServerBloc extends Bloc<ServerEvent, ServerState> {
  final GlobalKey rootKey;
  final ValueNotifier<String?> bottomTextNotifier;

  ServerBloc(this.rootKey, this.bottomTextNotifier)
      : super(ServerState(status: ServerStatus.initial)) {
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

  @override
  void onEvent(ServerEvent event) {
    if (kDebugMode) {
      print("[SERVER_BLOC] ${event.runtimeType}");
    }

    super.onEvent(event);
  }

  Future<(WebSocketChannel, MessageChannel)> _connectToServer(String serverIp, int port) async {
    final (websocketChannel, serverChannel) = await connectToServer(
      serverIp,
      port,
      () {
        add(ServerReset());
      },
    );

    return (websocketChannel, serverChannel);
  }

  Future<void> _onReset(ServerReset event, Emitter<ServerState> emit) async {
    await server_preferences.resetSharedPreferences();
    add(ServerInit());
  }

  Future<void> _onInit(ServerInit event, Emitter<ServerState> emit) async {
    /// Close any server or client connections that are open.
    if (state.databaseArgs case ServerDatabaseArgs(:var close) || ClientDatabaseArgs(:var close)) {
      await close();
    }

    /// Reset the state to initial.
    emit(ServerState(status: ServerStatus.initial).copyWith(status: ServerStatus.loading));
    bottomTextNotifier.value = "Loading server data...";

    /// Load the server data from the root key.
    switch (await server_preferences.getSavedDatabaseMode()) {
      case null:
        bottomTextNotifier.value = "Found no saved data.";
        add(ServerPromptingUserFromNull());

        return;
      case DatabaseMode.client:
        bottomTextNotifier.value = "Found existing client data.";

        var address = await server_preferences.getSavedServerAddress();

        if (address == null) {
          add(ServerPromptingServerInformation());
        } else {
          add(ServerLoadingClientFromPreferences(
            address: address,
            popupToUser: true,
            saveToPreferences: true,
          ));
        }
      case DatabaseMode.server:
        var port = await server_preferences.getSavedServerPort();
        bottomTextNotifier.value = "Found existing server data. $port";

        if (port == null) {
          add(ServerPromptingServerInformation());
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

    switch (await ServerModeSelectionDialog.show(rootKey.currentContext!)) {
      case _ when isClosed:
        return;
      case null:
        add(ServerPromptingUserFromNull());
      case DatabaseMode.client:
        bottomTextNotifier.value = "Client mode selected.";
        emit(state.copyWith(status: ServerStatus.promptingClientInformation));
        add(ServerPromptingClientInformation());
      case DatabaseMode.server:
        bottomTextNotifier.value = "Server mode selected.";
        emit(state.copyWith(status: ServerStatus.promptingServerInformation));
        add(ServerPromptingServerInformation());
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
    var context = rootKey.currentContext!;

    await ClientConnectionDialog.show(
      context: rootKey.currentContext!,
      onCreateServer: _connectToServer,
      onCancel: () {
        Navigator.of(context).pop();

        add(ServerPromptingUserFromNull());
      },
      onConfirm: (channel, args) async {
        Navigator.of(context).pop();

        add(
          ServerClientConnectionEstablished(
            saveToPreferences: true,
            popupToUser: true,
            channel: channel!,
            args: args,
          ),
        );
      },
    );
  }

  Future<void> _onLoadingClientFromPreferences(
    ServerLoadingClientFromPreferences event,
    Emitter<ServerState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: ServerStatus.loadingClient,
        databaseArgs: null,
        databaseHelper: null,
      ));

      final serverAddress = event.address;
      final [serverIp, portString] = serverAddress.split(":");
      final port = int.parse(portString);

      final (websocketChannel, serverChannel) = await connection_service.connectToServer(
        serverIp,
        port,
        () => add(ServerReset()),
      );

      add(
        ServerClientConnectionEstablished(
          saveToPreferences: event.saveToPreferences,
          popupToUser: false,
          args: ClientDatabaseArgs(
            parentIp: serverIp,
            port: port,
            webSocketChannel: websocketChannel,
            messageChannel: serverChannel,
            close: () async {
              await websocketChannel.sink.close();
            },
          ),
          channel: serverChannel,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      if (kDebugMode) {
        print(e);
      }
      add(ServerPromptingClientInformation());
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

    final defaultPort = () {
      var args = state.databaseArgs;
      if (args is ServerDatabaseArgs) {
        return args.port.toString();
      }
      return null;
    }();

    try {
      final localIp = await connection_service.getLocalIpAddress();
      if (isClosed) return;

      await ServerConfigurationDialog.show(
        context: rootKey.currentContext!,
        defaultPort: defaultPort,
        onStartServer: (port) => connection_service.startServer(port),
        onCancel: () => add(ServerPromptingUserFromNull()),
        onSuccess: (channel, close, port) {
          add(ServerServerStarted(
            saveToPreferences: true,
            popupToUser: true,
            channel: channel,
            args: ServerDatabaseArgs(
              ip: localIp,
              port: port,
              close: close,
            ),
          ));
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local IP or showing dialog: $e');
      }
      add(ServerPromptingUserFromNull());
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
      final (serverChannel, close) = await hostShelfServer(port);
      if (isClosed) return;

      add(ServerServerStarted(
        saveToPreferences: event.saveToPreferences,
        popupToUser: false,
        args: ServerDatabaseArgs(ip: localIp, port: port, close: close),
        channel: serverChannel,
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
        add(ServerPromptingServerInformation());
      }
    }
  }

  Future<void> _onClientConnectionEstablished(
    ServerClientConnectionEstablished event,
    Emitter<ServerState> emit,
  ) async {
    var address = '${event.args.parentIp}:${event.args.port}';
    bottomTextNotifier.value = "Connected to: $address";

    if (event.popupToUser) {
      final didUserCancelCompleter = Completer<bool>();
      await ClientConnectionSuccessDialog.show(
        context: rootKey.currentContext!,
        onCancel: () async {
          bottomTextNotifier.value = "Cancelled connection. Loading client data...";
          didUserCancelCompleter.complete(true);
          Navigator.of(rootKey.currentContext!).pop();
          final args = state.databaseArgs as ClientDatabaseArgs;
          await args.close();
          if (isClosed) return;

          add(ServerPromptingClientInformation());
        },
        onConfirm: () {
          // Dialog will be dismissed automatically
          Navigator.of(rootKey.currentContext!).pop();
          didUserCancelCompleter.complete(false);
        },
      );

      final didUserCancel = await didUserCancelCompleter.future;
      if (isClosed || didUserCancel) return;
    }

    emit(state.copyWith(
      status: ServerStatus.running,
      databaseArgs: event.args,
      databaseHelper: ServerDatabaseHelper(Server(event.channel)),
    ));
    postConnectionSetup(event.channel).listen(add);
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
        context: rootKey.currentContext!,
        serverIp: event.args.ip,
        port: event.args.port,
        onGoBack: () async {
          bottomTextNotifier.value = "Cancelled server. Loading server data...";
          didUserCancelCompleter.complete(true);
          Navigator.of(rootKey.currentContext!).pop();
          if (isClosed) return;

          var args = event.args;
          await args.close();
          if (isClosed) return;

          add(ServerPromptingServerInformation());
        },
        onConfirm: () {
          Navigator.of(rootKey.currentContext!).pop();
          didUserCancelCompleter.complete(false);
        },
      );

      final didUserCancel = await didUserCancelCompleter.future;
      if (isClosed || didUserCancel) return;
    }

    emit(state.copyWith(
      status: ServerStatus.running,
      databaseArgs: event.args,
      databaseHelper: ServerDatabaseHelper(Server(event.channel)),
    ));
    postServerSetup(event.channel).listen(add);
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
      if (state.databaseArgs case ServerDatabaseArgs(:var ip, :var port)) {
        bottomTextNotifier.value = "Hosting at: $ip:$port";
      } else if (state.databaseArgs case ClientDatabaseArgs(:var parentIp, :var port)) {
        bottomTextNotifier.value = "Connected to: $parentIp:$port";
      }
    });
  }
}
