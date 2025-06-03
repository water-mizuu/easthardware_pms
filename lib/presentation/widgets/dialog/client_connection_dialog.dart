import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:easthardware_pms/utils/try_future.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ClientConnectionDialog extends StatefulWidget {
  const ClientConnectionDialog({
    super.key,
    required this.onCancel,
    required this.onConnectToServer,
    required this.onConfirm,
  });

  final VoidCallback onCancel;

  final Future<(WebSocketChannel, MessageChannel, Stream<ServerEvent>)> Function(
    String serverIp,
    int port,
  ) onConnectToServer;
  final void Function(MessageChannel, ClientDatabaseArgs) onConfirm;

  @override
  State<ClientConnectionDialog> createState() => _ClientConnectionDialogState();

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onCancel,
    required Future<(WebSocketChannel, MessageChannel, Stream<ServerEvent>)> Function(
      String serverIp,
      int port,
    ) onConnectToServer,
    required void Function(MessageChannel, ClientDatabaseArgs) onConfirm,
  }) {
    return showSingleDialog(
      context,
      (context) => ClientConnectionDialog(
        onCancel: onCancel,
        onConnectToServer: onConnectToServer,
        onConfirm: onConfirm,
      ),
      dismissWithEsc: false,
    );
  }
}

class _ClientConnectionDialogState extends State<ClientConnectionDialog> {
  static const flex = [1, 1, 1, 1, 2];
  final focusNodes = List.generate(5, (_) => FocusNode());
  final controllers = List.generate(5, (_) => TextEditingController());

  var address = null as String?;
  var port = null as int?;

  var isConnecting = false;
  var testMessage = null as String?;
  var testMessageColor = null as Color?;

  var loadedWebSocketChannel = null as WebSocketChannel?;
  var loadedMessageChannel = null as MessageChannel?;
  var loadedStream = null as Stream<ServerEvent>?;

  void reset() {
    if (!context.mounted) return;
    setState(() {
      testMessage = null;
      testMessageColor = null;
      isConnecting = false;

      address = null;
      port = null;

      loadedWebSocketChannel = null;
      loadedMessageChannel = null;
      loadedStream = null;
    });
  }

  Future<void> _testConnection() async {
    reset();

    address = controllers.take(4).map((s) => s.text.trim()).join(".");
    port = int.parse(controllers.last.text.trim());

    final (result, error) = await widget.onConnectToServer(address!, port!).tryCatch();
    if (error case (final Object error, final StackTrace stackTrace)) {
      if (kDebugMode) {
        print("Failed to: $error");
        print(stackTrace);
      }

      setState(() {
        testMessage = "Failed to connect to $address:$port.";
        testMessageColor = Colors.red;
        isConnecting = false;
      });
      return;
    }

    final (webSocketChannel, messageChannel, stream) = result!;

    setState(() {
      testMessage = "Successfully connected to $address:$port.";
      testMessageColor = Colors.green;
      isConnecting = false;

      loadedWebSocketChannel = webSocketChannel;
      loadedMessageChannel = messageChannel;
      loadedStream = stream;
    });
  }

  Future<void> _confirm() async {
    if (loadedWebSocketChannel != null && loadedMessageChannel != null && loadedStream != null) {
      widget.onConfirm(
        loadedMessageChannel!,
        ClientDatabaseArgs(
          parentIp: address!,
          port: port!,
          webSocketChannel: loadedWebSocketChannel!,
          messageChannel: loadedMessageChannel!,
          stream: loadedStream!,
          close: () async {
            await loadedWebSocketChannel!.sink.close(0);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          controllers[i + 1].value = const TextEditingValue(text: " ");
                        }
                      } else {
                        if (i > 0) {
                          focusNodes[i].unfocus();
                          focusNodes[i - 1].requestFocus();
                          controllers[i].value = const TextEditingValue(text: "");

                          if (controllers[i - 1].text.isEmpty) {
                            controllers[i - 1].value = const TextEditingValue(text: " ");
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
            const Text(
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
          onPressed: widget.onCancel,
          child: const Text("Cancel"),
        ),
        if (address == null)
          Button(
            onPressed: _testConnection,
            child: const Text("Test Connection"),
          )
        else
          Button(
            onPressed: _confirm,
            child: const Text("OK"),
          ),
      ],
    );
  }
}
