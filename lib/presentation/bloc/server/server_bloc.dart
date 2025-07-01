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
import 'package:easthardware_pms/presentation/cubit/notifications/cubit/notification_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/client_connection_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/connection_lost_dialog.dart';
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

    // Reconnection event handlers
    on<_ServerConnectionLost>(_onConnectionLost);
    on<_ServerAttemptReconnection>(_onAttemptReconnection);
    on<ServerCancelReconnection>(_onCancelReconnection);
    on<_ServerReconnectionSucceeded>(_onReconnectionSucceeded);
    on<_ServerReconnectionFailed>(_onReconnectionFailed);

    on<ServerNotificationsReceived>(_onServerNotificationsReceived);

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
  ///   is disposed, the server attempts reconnection.
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

        /// If the connection is closed unexpectedly, trigger reconnection logic
        /// We also reset the authentication bloc but don't fully reset the server state
        final authenticationBloc = innerContext.read<AuthenticationBloc>();
        if (authenticationBloc.state.user != null) {
          authenticationBloc.add(const AuthenticationLogoutEvent());
        }

        // Trigger connection lost event instead of full reset
        add(const _ServerConnectionLost());
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
        print("Client connection failed: $e");
      }

      // Check if it's a network connectivity issue
      if (e.toString().contains('Could not determine local IP address') ||
          e.toString().contains('local IP') ||
          e.toString().contains('Network is unreachable') ||
          e.toString().contains('No route to host') ||
          e.toString().contains('Connection refused')) {
        emit(state.copyWith(
          bottomText: "Network connection issue. Please check your network connection.",
        ));

        if (event.popupToUser) {
          await _showNetworkConnectivityError();
          if (isClosed) return;
        }
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
      // Check if we're connected to a local network first
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

    try {
      // Check network connectivity first
      final localIp = await connection_service.getLocalIpAddress();
      if (isClosed) return;

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
    } catch (e) {
      if (e is SocketException && e.osError?.errorCode == 48) {
        /// If the port is already in use, we can either:
        ///   Connect to the existing server already running on that port.
        if (kDebugMode) {
          print("Port is already in use. Trying to connect to it.");
        }

        try {
          final localIp = await connection_service.getLocalIpAddress();
          add(_ServerLoadingClientFromPreferences(
            address: '$localIp:$port',
            saveToPreferences: false,
            popupToUser: false,
          ));
        } catch (networkError) {
          // Network connectivity issue while trying to connect to existing server
          await _showNetworkConnectivityError();
          if (isClosed) return;
          add(const _ServerPromptingUserFromNull());
        }
      } else if (e.toString().contains('Could not determine local IP address') ||
          e.toString().contains('local IP')) {
        // Network connectivity issue
        await _showNetworkConnectivityError();
        if (isClosed) return;
        add(const _ServerPromptingUserFromNull());
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
        showNotification.error(
          title: "Error",
          message: "Database helper is null",
        );
        return;
      }

      if (databaseHelper.database case final ResettableDatabase database) {
        await database.reset();
        showNotification.success(
          title: "Success",
          message: "Database has been reset successfully.",
        );
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

  Future<void> _onConnectionLost(
    _ServerConnectionLost event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(
      status: ServerStatus.disconnected,
      bottomText: "Connection lost. Preparing to reconnect...",
      lastDisconnectionTime: DateTime.now(),
      reconnectAttempts: 0,
    ));

    // Show the connection lost dialog and start the reconnection timer
    _showConnectionLostDialog();

    // Schedule the first reconnection attempt
    // ignore: discarded_futures
    Timer(const Duration(seconds: 5), () {
      if (!isClosed && state.status == ServerStatus.disconnected) {
        add(const _ServerAttemptReconnection());
      }
    });
  }

  void _showConnectionLostDialog() {
    const maxAttempts = 5;
    final nextRetryTime = DateTime.now().add(const Duration(seconds: 60));

    // Show the dialog without awaiting to avoid blocking the bloc
    // ignore: discarded_futures
    ConnectionLostDialog.show(
      onRetryNow: () {
        add(const _ServerAttemptReconnection());
      },
      onCancel: () {
        add(const ServerCancelReconnection());
      },
      reconnectAttempts: state.reconnectAttempts,
      maxReconnectAttempts: maxAttempts,
      nextReconnectTime: nextRetryTime,
    );
  }

  Timer? _reconnectTimer;

  Future<void> _onAttemptReconnection(
    _ServerAttemptReconnection event,
    Emitter<ServerState> emit,
  ) async {
    final currentAttempts = state.reconnectAttempts + 1;
    const maxAttempts = 5;

    if (currentAttempts > maxAttempts) {
      emit(state.copyWith(
        bottomText: "Max reconnection attempts reached. Returning to setup.",
      ));
      add(const _ServerPromptingUserFromNull());
      return;
    }

    emit(state.copyWith(
      status: ServerStatus.reconnecting,
      bottomText: "Attempting to reconnect... (Attempt $currentAttempts of $maxAttempts)",
      reconnectAttempts: currentAttempts,
    ));

    // Extract the last known good configuration
    final lastKnownArgs = state.databaseArgs;

    if (lastKnownArgs is ClientDatabaseArgs) {
      await _attemptClientReconnection(lastKnownArgs, emit, currentAttempts, maxAttempts);
    } else if (lastKnownArgs is ServerDatabaseArgs) {
      await _attemptServerReconnection(lastKnownArgs, emit, currentAttempts, maxAttempts);
    }
  }

  Future<void> _attemptClientReconnection(
    ClientDatabaseArgs lastKnownArgs,
    Emitter<ServerState> emit,
    int currentAttempts,
    int maxAttempts,
  ) async {
    try {
      // Close any existing connections first
      await lastKnownArgs.close?.call();

      final (webSocket, message, stream) = await _connectToServer(
        lastKnownArgs.parentIp,
        lastKnownArgs.port,
      );

      // Successfully reconnected
      emit(state.copyWith(
        status: ServerStatus.running,
        databaseArgs: ClientDatabaseArgs(
          parentIp: lastKnownArgs.parentIp,
          port: lastKnownArgs.port,
          webSocketChannel: webSocket,
          messageChannel: message,
          close: () async {
            await webSocket.sink.close();
          },
          stream: stream,
        ),
        databaseHelper: ServerDatabaseHelper(Server(message)),
        customChannel: WebSocketCustomChannel(message),
        bottomText: "Reconnected successfully to ${lastKnownArgs.parentIp}:${lastKnownArgs.port}",
        reconnectAttempts: 0,
      ));

      // Restart listening to the stream
      stream.listen(add);

      add(const _ServerReconnectionSucceeded());
    } catch (e) {
      if (kDebugMode) {
        print("Client reconnection attempt $currentAttempts failed: $e");
      }

      // Check if it's a network connectivity issue
      if (e.toString().contains('Could not determine local IP address') ||
          e.toString().contains('local IP') ||
          e.toString().contains('Network is unreachable') ||
          e.toString().contains('No route to host')) {
        emit(state.copyWith(
          status: ServerStatus.disconnected,
          bottomText: "Network connection lost. Please check your network connection.",
        ));

        // If we've tried multiple times and it's still a network issue, show the error
        if (currentAttempts >= 3) {
          await _showNetworkConnectivityError();
          if (isClosed) return;
          add(const ServerCancelReconnection());
          return;
        }
      }

      add(const _ServerReconnectionFailed());
    }
  }

  Future<void> _attemptServerReconnection(
    ServerDatabaseArgs lastKnownArgs,
    Emitter<ServerState> emit,
    int currentAttempts,
    int maxAttempts,
  ) async {
    try {
      // Close any existing servers first
      await lastKnownArgs.landingServer.close();
      await lastKnownArgs.webSocketServer.close();

      final port = lastKnownArgs.port;

      // Check network connectivity first
      final localIp = await connection_service.getLocalIpAddress();

      // Restart the servers
      final (landing, webSocket, stream) = await connection_service.startServers(port);

      // Successfully reconnected
      emit(state.copyWith(
        status: ServerStatus.running,
        databaseArgs: ServerDatabaseArgs(
          ip: localIp,
          port: port,
          landingServer: landing,
          webSocketServer: webSocket,
          stream: stream,
        ),
        databaseHelper: ServerDatabaseHelper(Server(webSocket.channel)),
        customChannel: WebSocketCustomChannel(webSocket.channel),
        bottomText: "Server restarted successfully at $localIp:$port",
        reconnectAttempts: 0,
      ));

      // Restart listening to the stream
      stream.listen(add);

      add(const _ServerReconnectionSucceeded());
    } catch (e) {
      if (kDebugMode) {
        print("Server reconnection attempt $currentAttempts failed: $e");
      }

      // Check if it's a network connectivity issue
      if (e.toString().contains('Could not determine local IP address') ||
          e.toString().contains('local IP')) {
        emit(state.copyWith(
          status: ServerStatus.disconnected,
          bottomText: "Network connection lost. Please check your network connection.",
        ));

        // If we've tried multiple times and it's still a network issue, show the error
        if (currentAttempts >= 3) {
          await _showNetworkConnectivityError();
          if (isClosed) return;
          add(const ServerCancelReconnection());
          return;
        }
      }

      add(const _ServerReconnectionFailed());
    }
  }

  Future<void> _onCancelReconnection(
    ServerCancelReconnection event,
    Emitter<ServerState> emit,
  ) async {
    _reconnectTimer?.cancel();

    emit(state.copyWith(
      bottomText: "Reconnection cancelled. Returning to setup.",
    ));

    // Return to the setup screen
    add(const _ServerPromptingUserFromNull());
  }

  Future<void> _onReconnectionSucceeded(
    _ServerReconnectionSucceeded event,
    Emitter<ServerState> emit,
  ) async {
    _reconnectTimer?.cancel();

    // The state is already updated in the attempt methods
    // Reset the bottom text after a short delay
    // ignore: discarded_futures
    Timer(const Duration(seconds: 3), () {
      if (!isClosed && state.status == ServerStatus.running) {
        add(const _ServerResetBottomText());
      }
    });
  }

  Future<void> _onReconnectionFailed(
    _ServerReconnectionFailed event,
    Emitter<ServerState> emit,
  ) async {
    const maxAttempts = 5;
    final currentAttempts = state.reconnectAttempts;

    if (currentAttempts >= maxAttempts) {
      emit(state.copyWith(
        status: ServerStatus.disconnected,
        bottomText: "Maximum reconnection attempts reached. Please check your connection.",
      ));
      return;
    }

    emit(state.copyWith(
      status: ServerStatus.disconnected,
      bottomText: "Reconnection failed. Will retry in 60 seconds...",
    ));

    // Schedule the next reconnection attempt
    _reconnectTimer = Timer(const Duration(seconds: 60), () {
      if (!isClosed && state.status == ServerStatus.disconnected) {
        add(const _ServerAttemptReconnection());
      }
    });
  }

  /// Shows a user-friendly error dialog when the device is not connected to a network
  Future<void> _showNetworkConnectivityError() async {
    final context = rootWidgetKey.currentContext;
    if (context == null || !context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ContentDialog(
          title: const Text('Network Connection Required'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To host or connect to a server, you need to be connected to a local network (WiFi or Ethernet).',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Please check:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• WiFi connection is enabled and connected'),
              Text('• Ethernet cable is properly connected'),
              Text('• Network adapter is functioning correctly'),
              SizedBox(height: 16),
              Text(
                'Once connected to a network, try again.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onServerNotificationsReceived(
    ServerNotificationsReceived event,
    Emitter<ServerState> emit,
  ) async {
    final notificationCubit = rootWidgetKey.currentContext?.read<NotificationCubit>();
    if (notificationCubit == null) return;

    for (final notification in event.notifications) {
      notificationCubit.addNotificationFromServer(notification);
    }
  }

  @override
  Future<void> close() {
    _reconnectTimer?.cancel();
    return super.close();
  }

  @override
  String toString() {
    return 'ServerBloc{status: ${state.status}, databaseArgs: ${state.databaseArgs}}';
  }
}

typedef MockUser = ({
  String firstName,
  String lastName,
  AccessLevel accessLevel,
  List<SecurityQuestion> securityQuestions,
});
