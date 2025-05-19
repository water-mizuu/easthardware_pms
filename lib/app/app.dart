import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:async_queue/async_queue.dart';
import 'package:easthardware_pms/app/dependency_injector.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/userloglist/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/utils/parallelism.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:shelf/shelf_io.dart" as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class BottomTextNotifier {
  final ValueNotifier<String> notifier;

  const BottomTextNotifier(this.notifier);
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<StatefulWidget> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final AsyncQueue asyncQueue = AsyncQueue.autoStart();
  late final GlobalKey<NavigatorState> rootKey = GlobalKey();
  late DependencyInjector di;
  late final ValueNotifier<String> bottomText;

  @override
  void initState() {
    super.initState();

    di = DependencyInjector();
    di.init(null);

    bottomText = ValueNotifier<String>("");

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConfiguration());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      final user = context.read<AuthenticationBloc>().state.user;
      if (user != null) {
        context.read<UserLogListBloc>().add(AddLogoutEvent(user));
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [...di.inject(), Provider.value(value: BottomTextNotifier(bottomText))],
      child: FluentApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router(rootKey),
        themeMode: ThemeMode.light,
        theme: FluentThemeData(micaBackgroundColor: Colors.grey[10]),
      ),
    );
  }

  /// Reads the database mode from shared preferences and prompts the user as necessary.
  Future<void> _loadConfiguration() async {
    var sharedPreferences = SharedPreferencesAsync();
    var mode = await sharedPreferences.getInt("mode");
    var databaseMode = mode == null ? null : DatabaseMode.values[mode];

    switch (databaseMode) {
      case null:
        asyncQueue.addJob((_) async => promptUserForOption());
        break;
      case DatabaseMode.client:
        break;
      case DatabaseMode.server:
        break;
    }
  }

  /// Verifies if the widget is mounted and the context is valid.
  ///   Throws an [Error] if the widget is not mounted or the context is invalid.
  ///   This is useful to ensure that the widget is still in the widget tree
  void verifyMounted() {
    if (!mounted ||
        !context.mounted ||
        rootKey.currentContext == null ||
        !rootKey.currentContext!.mounted) {
      throw Error();
    }
  }

  Future<void> promptUserForOption() async {
    try {
      verifyMounted();

      var typeCompleter = Completer<DatabaseMode>();
      showDialog(
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
      var result = await typeCompleter.future;
      verifyMounted();
      switch (result) {
        case DatabaseMode.client:
          asyncQueue.addJob((_) => _promptUserForClient());
          break;
        case DatabaseMode.server:
          asyncQueue.addJob((_) => _promptUserForServer());
          break;
      }
    } finally {}
  }

  /// TODO: Implement the client mode.
  Future<void> _promptUserForClient() async {
    final focusNodes = List.generate(5, (_) => FocusNode());
    final controllers = List.generate(5, (_) => TextEditingController());

    try {
      verifyMounted();

      var testMessage = null as String?;
      var isConnecting = false;

      await showDialog(
        context: rootKey.currentContext!,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
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
                      for (var i = 0; i < focusNodes.length; i++) ...[
                        if (i == focusNodes.length - 1) const Text(":"),
                        Expanded(
                          flex: i == focusNodes.length - 1 ? 2 : 1,
                          child: TextFormBox(
                            focusNode: focusNodes[i],
                            controller: controllers[i],
                            autofocus: i == 0,
                            onChanged: (value) {
                              setState(() {
                                testMessage = null;
                                isConnecting = false;
                              });

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
                  if (testMessage != null) ...[
                    const SizedBox(height: 12.0),
                    Text(
                      testMessage!,
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ],
              ),
              actions: [
                Button(
                  child: const Text("Test Connection"),
                  onPressed: () async {
                    final host = controllers.take(4).map((s) => s.text).join(".");
                    final port = controllers.last.text.trim();

                    final ipAddress = "$host:$port";
                    setState(() {
                      isConnecting = true;
                      testMessage = null;
                    });

                    await Future.delayed(const Duration(seconds: 2));
                    if (!mounted || !context.mounted) return;

                    final isValid = Random().nextBool();

                    setState(() {
                      isConnecting = false;
                      testMessage = isValid
                          ? "Connection to $ipAddress was successful."
                          : "Connection to $ipAddress failed.";
                    });
                  },
                ),
                Button(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
        },
      );
    } finally {
      for (var focusNode in focusNodes) {
        focusNode.dispose();
      }
      for (var controller in controllers) {
        controller.dispose();
      }
    }
  }

  Future<void> _promptUserForServer() async {
    final portController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    try {
      verifyMounted();

      final deviceIp = await NetworkInfo().getWifiIP().then((p) => p!);
      verifyMounted();

      var testMessage = null as String?;
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
                    if (testMessage case var testMessage?) ...[
                      const SizedBox(height: 12.0),
                      Text(
                        testMessage,
                        style: TextStyle(color: Colors.black),
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
                    asyncQueue.addJob((_) {
                      return promptUserForOption();
                    });
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
                        var port = int.parse(portController.text);
                        if (port < 2000 || port > 65535) {
                          throw Exception("Port number must be between 2000 and 65535.");
                        }
                        await Future.delayed(const Duration(seconds: 2));
                        verifyMounted();

                        var (channel, hostedPort, close) = await hostShelfServer(port);
                        verifyMounted();

                        if (!context.mounted) return;
                        bottomText.value = "Server started at $deviceIp:$hostedPort";
                        Navigator.of(context).pop();
                        asyncQueue.addJob((_) {
                          return _promptUserServerSuccess(channel, close, deviceIp, hostedPort);
                        });
                      } catch (e) {
                        if (!mounted || !context.mounted) return;

                        setState(() {
                          isConnecting = false;
                          testMessage = "Failed to start server: $e";
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

  Future<void> _promptUserServerSuccess(
    ServerChannel channel,
    Future<void> Function() close, //
    String ip,
    int port,
  ) async {
    try {
      verifyMounted();

      const flex = [1, 1, 1, 1, 2];

      var ipParts = ip.split(".");
      var addressParts = [...ipParts, port.toString()];

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
                  Navigator.of(context).pop();
                  await close();
                  verifyMounted();

                  asyncQueue.addJob((_) => _promptUserForServer());
                },
              ),
              Button(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } finally {}
  }
}

enum DatabaseMode { client, server }

class ServerChannel {
  final ListenedReceivePort receivePort;
  final SendPort sendPort;

  ServerChannel(this.receivePort, this.sendPort);

  dynamic invoke(String method, [List<Object?>? arguments]) {
    sendPort.send([method, arguments]);
    return receivePort.next();
  }
}

Future<(ServerChannel, int, Future<void> Function() close)> hostShelfServer(int port) async {
  var receivePort = ReceivePort().hostListener();
  await Isolate.spawn(_spawnIsolate, (
    RootIsolateToken.instance!,
    receivePort.sendPort,
    port,
  ));
  var sendPort = await receivePort.next<SendPort>();
  var receivedServerPort = await receivePort.next<int>();
  assert(receivedServerPort == port, "The server port is not the same as the one provided.");

  var channel = ServerChannel(receivePort, sendPort);

  return (
    channel,
    port,
    () async {
      var received = await channel.invoke("stop");
      receivePort.close();
      if (kDebugMode) {
        print("Isolate killed.");
      }
      if (received != 0) {
        throw Exception("Failed to stop the isolate.");
      }
    }
  );
}

Future<void> _spawnIsolate((RootIsolateToken, SendPort, int) payload) async {
  var (token, sendPort, givenPort) = payload;
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  var receivePort = ReceivePort().hostListener();
  sendPort.send(receivePort.sendPort);
  var server = await _shelfInitiate(givenPort, (channel, [subprotocol]) async {
    // Handle WebSocket connection
    channel.sink.add("Hello from the server!");
  });

  sendPort.send(server.port);

  var isRunning = true;
  while (isRunning) {
    var message = await receivePort.next();

    if (message case ["stop", _]) {
      isRunning = false;
      await server.close();
      receivePort.close();
      if (kDebugMode) {
        print("Isolate stopped.");
      }
      sendPort.send(0);
    } else {
      if (kDebugMode) {
        print("Received unexpected message: $message");
      }
    }
  }

  if (kDebugMode) {
    print("Isolate finished.");
  }
}

/// Initializes the shelf server, returning the server instance and the port.
/// The port MAY need to be user modifiable.
///   There is no guarantee that the port will be the same as the one provided.
///    Otherwise, the port will be the same as the one provided.)
Future<HttpServer> _shelfInitiate(
  int port,
  FutureOr<void> Function(WebSocketChannel channel, [String? subprotocol]) onConnect,
) async {
  assert(RootIsolateToken.instance == null, "This function must be called from another isolate.");
  var network = NetworkInfo();

  var ip = await network.getWifiIP().then((p) => p!);
  var handler = webSocketHandler(onConnect);
  var server = await shelf_io.serve(handler, ip, port);
  var hostedPort = server.port;

  if (kDebugMode) {
    print("Serving at $ip:$hostedPort");
  }

  return server;
}
