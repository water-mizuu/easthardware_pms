import 'dart:async';
import 'dart:io';

import 'package:easthardware_pms/app/app.dart';
import 'package:easthardware_pms/backend/server_mode.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/utils/server_channel.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ServerBloc extends Bloc<ServerEvent, ServerState> {
  final GlobalKey rootKey;
  final ValueNotifier<String?> bottomTextNotifier;

  ServerBloc(this.rootKey, this.bottomTextNotifier)
      : super(ServerState(status: ServerStatus.initial)) {
    on<ServerInit>((event, emit) async {
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
          var address = await sharedPreferences.getString("server_address");

          if (address == null) {
            add(ServerPromptingServerInformation());
          } else {
            add(ServerLoadingClientFromPreferences(address: address));
          }

          return;
        case DatabaseMode.server:
          bottomTextNotifier.value = "Found existing server data.";
          var port = await sharedPreferences.getString("port");

          if (port == null) {
            add(ServerPromptingServerInformation());
          } else {
            add(ServerLoadingServerFromPreferences(port: int.parse(port)));
          }

          return;
      }
    });
    on<ServerPromptingUserFromNull>((event, emit) async {
      emit(state.copyWith(status: ServerStatus.promptingUser));

      final typeCompleter = Completer<DatabaseMode>();
      await showDialog(
        context: rootKey.currentContext!,
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
                onPressed: () {
                  Navigator.of(context).pop();
                  typeCompleter.complete(DatabaseMode.client);
                },
              ),
              Button(
                child: const Text("Server"),
                onPressed: () {
                  Navigator.of(context).pop();
                  typeCompleter.complete(DatabaseMode.server);
                },
              ),
            ],
          );
        },
      );

      final result = await typeCompleter.future;
      if (isClosed) return;

      switch (result) {
        case DatabaseMode.client:
          bottomTextNotifier.value = "Client mode selected.";
          emit(state.copyWith(status: ServerStatus.promptingClientInformation));
          add(ServerPromptingClientInformation());
        case DatabaseMode.server:
          bottomTextNotifier.value = "Server mode selected.";
          emit(state.copyWith(status: ServerStatus.promptingServerInformation));
          add(ServerPromptingServerInformation());
      }
    });

    on<ServerPromptingClientInformation>((event, emit) async {
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

        final promptCompleter = Completer<void>();

        await showDialog(
          context: rootKey.currentContext!,
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

              void onTestConnection() async {
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
              }

              void onConfirmation() async {
                Navigator.of(context).pop();

                promptCompleter.complete();
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
                                    controllers[i].value =
                                        TextEditingValue(text: value.trimRight());
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
                      promptCompleter.complete();
                    },
                  ),
                  if (loadedWebsocketChannel == null)
                    Button(
                      onPressed: onTestConnection,
                      child: const Text("Test Connection"),
                    )
                  else
                    Button(
                      onPressed: onConfirmation,
                      child: const Text("OK"),
                    ),
                ],
              );
            });
          },
        );

        await promptCompleter.future;
        if (isClosed || rootKey.currentContext?.mounted != true) return;

        add(
          ServerClientConnectionEstablished(
            channel: loadedServerChannel!,
            args: ClientDatabaseArgs(
              parentIp: parentIp!,
              port: port!,
              webSocketChannel: loadedWebsocketChannel,
              serverChannel: loadedServerChannel,
              close: () async {
                // By closing the websocket channel, we are also closing the server channel.
                await loadedWebsocketChannel!.sink.close(0);
              },
            ),
          ),
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
    });
    on<ServerLoadingClientFromPreferences>((event, emit) async {
      emit(state.copyWith(
        status: ServerStatus.loadingClient,
        databaseArgs: null,
        databaseHelper: null,
      ));

      /// Load the client data from the root key.
      final sharedPreferences = SharedPreferencesAsync();
      final serverIp = await sharedPreferences.getString("serverIp");
      final port = await sharedPreferences.getInt("port");

      if (serverIp == null || port == null) {
        add(ServerPromptingServerInformation());
        return;
      }

      final (websocketChannel, serverChannel) = await _connectToServer(serverIp, port);

      emit(state.copyWith(
        status: ServerStatus.promptingClientInformation,
        databaseArgs: ClientDatabaseArgs(
          parentIp: serverIp,
          port: port,
          webSocketChannel: websocketChannel,
          serverChannel: serverChannel,
          close: () async {
            // By closing the websocket channel, we are also closing the server channel.
            await websocketChannel.sink.close(0);
          },
        ),
        databaseHelper: ServerDatabaseHelper(Server(serverChannel)),
      ));
    });

    on<ServerPromptingServerInformation>((event, emit) async {
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
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop();

                      add(ServerPromptingUserFromNull());
                    },
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
    });
    on<ServerLoadingServerFromPreferences>((event, emit) async {
      emit(state.copyWith(
        status: ServerStatus.loadingServer,
        databaseArgs: null,
        databaseHelper: null,
      ));

      /// Load the server data from the root key.
      final port = event.port;

      try {
        final (serverChannel, close) = await _hostServer(port);
        add(ServerServerStarted(
          args: ServerDatabaseArgs(ip: "localhost", port: port, close: close),
          channel: serverChannel,
        ));
      } on SocketException {
        add(ServerPromptingServerInformation());
      }
    });

    on<ServerClientConnectionEstablished>((event, emit) async {
      bottomTextNotifier.value = "Connected to: ${event.args.parentIp}:${event.args.port}";

      emit(state.copyWith(
        status: ServerStatus.running,
        databaseArgs: event.args,
        databaseHelper: ServerDatabaseHelper(Server(event.channel)),
      ));

      await showDialog(
        context: rootKey.currentContext!,
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
    });
    on<ServerServerStarted>((event, emit) async {
      bottomTextNotifier.value = "Hosting at: ${event.args.ip}:${event.args.port}";

      emit(state.copyWith(
        status: ServerStatus.running,
        databaseArgs: event.args,
        databaseHelper: ServerDatabaseHelper(Server(event.channel)),
      ));

      const flex = [1, 1, 1, 1, 2];
      final ipParts = event.args.ip.split(".");
      final addressParts = [...ipParts, event.args.port.toString()];

      await showDialog(
        context: rootKey.currentContext!,
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

                  var args = state.databaseArgs as ServerDatabaseArgs;
                  await args.close();

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
    });
  }

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
    if (kDebugMode) {
      print((next, isSuccessful));
    }
    if (!isSuccessful) throw Error();
    return (websocketChannel, serverChannel);
  }
}

sealed class ServerEvent {
  const ServerEvent();
}

class ServerInit extends ServerEvent {
  const ServerInit();
}

class ServerPromptingUserFromNull extends ServerEvent {
  const ServerPromptingUserFromNull();
}

class ServerLoadingClientFromPreferences extends ServerEvent {
  const ServerLoadingClientFromPreferences({required this.address});

  final String address;
}

class ServerPromptingClientInformation extends ServerEvent {
  const ServerPromptingClientInformation();
}

class ServerClientConnectionEstablished extends ServerEvent {
  const ServerClientConnectionEstablished({required this.args, required this.channel});

  final ClientDatabaseArgs args;
  final ServerChannel channel;
}

class ServerLoadingServerFromPreferences extends ServerEvent {
  const ServerLoadingServerFromPreferences({required this.port});

  final int port;
}

class ServerPromptingServerInformation extends ServerEvent {
  const ServerPromptingServerInformation();
}

class ServerServerStarted extends ServerEvent {
  const ServerServerStarted({required this.args, required this.channel});

  final ServerDatabaseArgs args;
  final ServerChannel channel;
}

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
