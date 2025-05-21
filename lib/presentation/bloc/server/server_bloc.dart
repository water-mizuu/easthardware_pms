import 'dart:async';
import 'dart:io';

import 'package:easthardware_pms/app/app.dart';
import 'package:easthardware_pms/backend/extensions/to_server_channel.dart';
import 'package:easthardware_pms/backend/host_shelf.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_event.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_state.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/utils/server_channel.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  }

  /// Resets the shared preferences by removing the server address, port, and mode.
  ///   Returns the instance of SharedPreferencesAsync.
  Future<SharedPreferencesAsync> _resetSharedPreferences() async {
    final sharedPreferences = SharedPreferencesAsync();
    await sharedPreferences.remove("serverAddress");
    await sharedPreferences.remove("port");
    await sharedPreferences.remove("mode");

    return sharedPreferences;
  }

  /// Starts a shelf server on the given port.
  Future<(ServerChannel, Future<void> Function())> _hostServer(int port) async {
    final (serverChannel, hostedPort, close) = await hostShelfServer(port);
    assert(hostedPort == port, "Hosted port should be the same as the given port.");

    return (serverChannel, close);
  }

  Future<(WebSocketChannel, ServerChannel)> _connectToServer(String server, int port) async {
    final uri = Uri.parse("ws://$server:$port");
    if (kDebugMode) {
      print("Connecting to $uri");
    }
    final websocketChannel = WebSocketChannel.connect(uri);
    await websocketChannel.ready;

    final serverChannel = websocketChannel.toServerChannel();
    final next = await serverChannel.receivePort.next();
    final isSuccessful = next == 0;
    if (!isSuccessful) throw Error();

    return (websocketChannel, serverChannel);
  }

  Future<void> _onReset(ServerReset event, Emitter<ServerState> emit) async {
    await _resetSharedPreferences();
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

    final sharedPreferences = SharedPreferencesAsync();
    final mode = await sharedPreferences.getInt("mode");
    final databaseMode = mode == null ? null : DatabaseMode.values[mode];

    switch (databaseMode) {
      case null:
        bottomTextNotifier.value = "Found no saved data.";
        add(ServerPromptingUserFromNull());

        return;
      case DatabaseMode.client:
        bottomTextNotifier.value = "Found existing client data.";
        var address = await sharedPreferences.getString("serverAddress");

        if (address == null) {
          add(ServerPromptingServerInformation());
        } else {
          add(ServerLoadingClientFromPreferences(address: address));
        }

        return;
      case DatabaseMode.server:
        var port = await sharedPreferences.getInt("port");
        bottomTextNotifier.value = "Found existing server data. $port";

        if (port == null) {
          add(ServerPromptingServerInformation());
        } else {
          add(ServerLoadingServerFromPreferences(port: port));
        }

        return;
    }
  }

  Future<void> _onPromptingUserFromNull(
    ServerPromptingUserFromNull event,
    Emitter<ServerState> emit,
  ) async {
    emit(state.copyWith(status: ServerStatus.promptingUser));

    final result = await showDialog<DatabaseMode>(
      context: rootKey.currentContext!,
      dismissWithEsc: false,
      builder: (context) {
        return ContentDialog(
          title: const Text("Select Client Mode"),
          content: const Text(
            "It seems that you have not selected a client type. "
            "Please select the client type for this device. "
            "If this is to be the main computer, select server. "
            "If this is a client computer, select client.",
            style: TextStyle(height: 1.5),
            textAlign: TextAlign.justify,
          ),
          actions: [
            Button(
              child: const Text("Client"),
              onPressed: () => Navigator.of(context).pop(DatabaseMode.client),
            ),
            Button(
              child: const Text("Server"),
              onPressed: () => Navigator.of(context).pop(DatabaseMode.server),
            ),
          ],
        );
      },
    );

    if (isClosed) return;
    switch (result) {
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

    const flex = [1, 1, 1, 1, 2];
    final focusNodes = List.generate(5, (_) => FocusNode());
    final controllers = List.generate(5, (_) => TextEditingController());

    try {
      if (isClosed) return;

      var parentIp = null as String?;
      var port = null as int?;

      var testMessage = null as String?;
      var testMessageColor = null as Color?;
      var isConnecting = false;
      var loadedWebsocketChannel = null as WebSocketChannel?;
      var loadedServerChannel = null as ServerChannel?;

      await showDialog(
        context: rootKey.currentContext!,
        dismissWithEsc: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            void reset() {
              if (!context.mounted) return;
              setState(() {
                testMessage = null;
                testMessageColor = null;
                isConnecting = false;

                loadedWebsocketChannel?.sink.close();
                loadedWebsocketChannel = null;
                loadedServerChannel = null;
              });
            }

            return ContentDialog(
              title: const Text("Client Mode"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "You have selected client mode. "
                    "Please enter the server IP address.",
                    style: TextStyle(height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      for (var i = 0; i < flex.length; i++) ...[
                        if (i == focusNodes.length - 1) const Text(":"),
                        Expanded(
                          flex: flex[i],
                          child: TextFormBox(
                            focusNode: focusNodes[i],
                            controller: controllers[i],
                            autofocus: i == 0,
                            onChanged: (value) {
                              reset();

                              if (value.trim().isNotEmpty) {
                                if (value[value.length - 1] == " " && i < focusNodes.length - 1) {
                                  focusNodes[i].unfocus();
                                  focusNodes[i + 1].requestFocus();
                                  controllers[i].value = TextEditingValue(text: value.trimRight());
                                  controllers[i + 1].value = TextEditingValue(text: " ");
                                }
                              } else {
                                if (i > 0) {
                                  focusNodes[i].unfocus();
                                  focusNodes[i - 1].requestFocus();
                                  controllers[i].value = TextEditingValue(text: "");

                                  if (controllers[i - 1].text.isEmpty) {
                                    controllers[i - 1].value = TextEditingValue(text: " ");
                                  }
                                }
                              }
                            },
                          ),
                        )
                      ],
                    ].withSpacing(() => const SizedBox(width: 4.0)),
                  ),
                  if (isConnecting) ...[
                    const SizedBox(height: 12.0),
                    const ProgressRing(
                      strokeWidth: 2.0,
                      value: null,
                    ),
                    Text(
                      "Connecting...",
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                  if (testMessage != null && testMessageColor != null) ...[
                    const SizedBox(height: 12.0),
                    Text(
                      testMessage!,
                      style: TextStyle(color: testMessageColor),
                    ),
                  ],
                ],
              ),
              actions: [
                Button(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();

                    add(ServerPromptingUserFromNull());
                  },
                ),
                if (loadedWebsocketChannel == null)
                  Button(
                    onPressed: () async {
                      parentIp = controllers.take(4).map((s) => s.text.trim()).join(".");
                      port = int.parse(controllers.last.text.trim());

                      final ipAddress = "$parentIp:$port";
                      reset();

                      if (isClosed || !context.mounted) return;

                      try {
                        final (websocketChannel, serverChannel) =
                            await _connectToServer(parentIp!, port!);
                        setState(() {
                          testMessage = "Successfully connected to $ipAddress.";
                          testMessageColor = Colors.green;
                          isConnecting = false;

                          loadedWebsocketChannel = websocketChannel;
                          loadedServerChannel = serverChannel;
                        });
                      } on Object {
                        reset();

                        setState(() {
                          testMessage = "Failed to connect to $ipAddress.";
                          testMessageColor = Colors.red;
                          isConnecting = false;
                        });
                      }
                    },
                    child: const Text("Test Connection"),
                  )
                else
                  Button(
                    onPressed: () async {
                      Navigator.of(context).pop();

                      if (isClosed || rootKey.currentContext?.mounted != true) return;
                      add(
                        ServerClientConnectionEstablished(
                          saveToPreferences: true,
                          popupToUser: true,
                          channel: loadedServerChannel!,
                          args: ClientDatabaseArgs(
                            parentIp: parentIp!,
                            port: port!,
                            webSocketChannel: loadedWebsocketChannel,
                            serverChannel: loadedServerChannel,
                            close: () async {
                              await loadedWebsocketChannel!.sink.close(0);
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text("OK"),
                  ),
              ],
            );
          });
        },
      );
    } on Error {
      add(ServerPromptingUserFromNull());
    } finally {
      for (final focusNode in focusNodes) {
        focusNode.dispose();
      }
      for (final controller in controllers) {
        controller.dispose();
      }
    }
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

      /// Load the client data from the root key.
      final serverAddress = event.address;
      final [serverIp, portString] = serverAddress.split(":");
      final port = int.parse(portString);

      final (websocketChannel, serverChannel) = await _connectToServer(serverIp, port);

      add(
        ServerClientConnectionEstablished(
          saveToPreferences: event.saveToPreferences,
          popupToUser: false,
          args: ClientDatabaseArgs(
            parentIp: serverIp,
            port: port,
            webSocketChannel: websocketChannel,
            serverChannel: serverChannel,
            close: () async {
              // By closing the websocket channel, we are also closing the server channel.
              await websocketChannel.sink.close(0);
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
    final portController = TextEditingController(text: defaultPort);
    final formKey = GlobalKey<FormState>();

    try {
      var localIp = await NetworkInfo().getWifiIP().then((p) => p!);
      if (isClosed) return;

      /// Inner state of the dialog.
      var testMessage = null as String?;
      var testMessageColor = null as Color?;
      var isConnecting = false;

      await showDialog(
        context: rootKey.currentContext!,
        dismissWithEsc: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return ContentDialog(
              title: const Text("Server Mode"),
              content: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.always,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "You have selected server mode. "
                      "Enter a port number you want to assign the server. "
                      "(Any number between 2000 and 65535 is valid.)",
                      style: TextStyle(height: 1.5),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 12.0),
                    TextFormBox(
                      controller: portController,
                      placeholder: "Port",
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Port number is required.";
                        }
                        final port = int.tryParse(value);
                        if (port == null || port < 2000 || port > 65535) {
                          return "Port number must be between 2000 and 65535.";
                        }
                        return null;
                      },
                      autofocus: true,
                      onChanged: (value) {
                        setState(
                          () {
                            testMessage = null;
                            isConnecting = false;
                          },
                        );
                      },
                    ),
                    if (isConnecting) ...[
                      const SizedBox(height: 12.0),
                      const ProgressRing(
                        strokeWidth: 2.0,
                        value: null,
                      ),
                      Text(
                        "Connecting...",
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                    if (testMessage case final testMessage?) ...[
                      const SizedBox(height: 12.0),
                      Text(
                        testMessage,
                        style: TextStyle(color: testMessageColor!),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                Button(
                  onPressed: () {
                    Navigator.of(context).pop();

                    add(ServerPromptingUserFromNull());
                  },
                  child: Text("Cancel"),
                ),
                Button(
                  onPressed: () {
                    if (isConnecting) return null;

                    return () async {
                      setState(() {
                        isConnecting = true;
                        testMessage = null;
                      });

                      try {
                        final port = int.parse(portController.text);
                        if (port < 2000 || port > 65535) {
                          throw Exception("Port number must be between 2000 and 65535.");
                        }
                        if (isClosed) return;

                        final (channel, close) = await _hostServer(port);
                        if (isClosed || !context.mounted) return;
                        Navigator.of(context).pop();

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
                      } on SocketException catch (e) {
                        if (e.osError case OSError(errorCode: 48)) {
                          setState(() {
                            isConnecting = false;
                            testMessage = "Port is already in use.";
                            testMessageColor = Colors.red;
                          });
                        } else {
                          rethrow;
                        }
                      } catch (e) {
                        if (isClosed || !context.mounted) return;

                        setState(() {
                          isConnecting = false;
                          testMessage = "Failed to start server: $e";
                          testMessageColor = Colors.red;
                        });
                      }
                    };
                  }(),
                  child: const Text("Start server"),
                )
              ],
            );
          });
        },
      );
    } finally {
      portController.dispose();
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
      final (serverChannel, close) = await _hostServer(port);
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
        ///   Show a dialog to the user and ask them to select a new port,
        ///   OR
        ///   Connect to the existing server already running on that port.

        if (kDebugMode) {
          print("Port is already in use. Trying to connect to it.");
        }

        await _resetSharedPreferences();
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

    emit(state.copyWith(
      status: ServerStatus.running,
      databaseArgs: event.args,
      databaseHelper: ServerDatabaseHelper(Server(event.channel)),
    ));

    await showDialog(
      context: rootKey.currentContext!,
      dismissWithEsc: false,
      builder: (context) {
        return ContentDialog(
          title: const Text("Client Connected"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Client connected successfully. ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: "You may now sign in.",
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
          actions: [
            Button(
              child: const Text("Cancel"),
              onPressed: () async {
                bottomTextNotifier.value = "Cancelled connection. Loading client data...";
                Navigator.of(context).pop();
                var args = state.databaseArgs as ClientDatabaseArgs;
                await args.close();

                add(ServerPromptingClientInformation());
              },
            ),
            Button(
              child: const Text("OK"),
              onPressed: () async {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    if (event.saveToPreferences) {
      add(ServerSaveClientInformation(serverAddress: address));
    }
  }

  /// This runs whenever a server is started.
  Future<void> _onServerStarted(ServerServerStarted event, Emitter<ServerState> emit) async {
    var address = '${event.args.ip}:${event.args.port}';
    bottomTextNotifier.value = "Hosting at: $address";

    const flex = [1, 1, 1, 1, 2];
    final ipParts = event.args.ip.split(".");
    final addressParts = [...ipParts, event.args.port.toString()];

    if (event.popupToUser) {
      await showDialog(
        context: rootKey.currentContext!,
        dismissWithEsc: false,
        builder: (context) {
          return ContentDialog(
            title: const Text("Server Started"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Server started successfully. ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: "Client devices can now connect to the server "
                            "using the IP address below.",
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    for (var i = 0; i < flex.length; i++) ...[
                      if (i == flex.length - 1) const Text(":"),
                      Expanded(
                        flex: flex[i],
                        child: TextFormBox(
                          initialValue: addressParts[i],
                          autofocus: false,
                        ),
                      )
                    ],
                  ].withSpacing(() => const SizedBox(width: 4.0)),
                )
              ],
            ),
            actions: [
              Button(
                child: const Text("Go back"),
                onPressed: () async {
                  bottomTextNotifier.value = "Cancelled server. Loading server data...";
                  Navigator.of(context).pop();
                  if (isClosed) return;

                  var args = event.args;
                  await args.close();
                  if (isClosed) return;

                  add(ServerPromptingServerInformation());
                },
              ),
              Button(
                child: const Text("OK"),
                onPressed: () async {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    emit(state.copyWith(
      status: ServerStatus.running,
      databaseArgs: event.args,
      databaseHelper: ServerDatabaseHelper(Server(event.channel)),
    ));

    if (event.saveToPreferences) {
      add(ServerSaveServerInformation(port: event.args.port));
    }
  }

  Future<void> _saveClientInformation(
    ServerSaveClientInformation event,
    Emitter<ServerState> emit,
  ) async {
    if (kDebugMode) {
      print("Saving client information: ${event.serverAddress}");
    }

    final sharedPreferences = await _resetSharedPreferences();
    await sharedPreferences.setString("serverAddress", event.serverAddress);
    await sharedPreferences.setInt("mode", DatabaseMode.client.index);
  }

  Future<void> _saveServerInformation(
    ServerSaveServerInformation event,
    Emitter<ServerState> emit,
  ) async {
    if (kDebugMode) {
      print("Saving server information: ${event.port}");
    }

    final sharedPreferences = await _resetSharedPreferences();
    await sharedPreferences.setInt("port", event.port);
    await sharedPreferences.setInt("mode", DatabaseMode.server.index);
  }
}
