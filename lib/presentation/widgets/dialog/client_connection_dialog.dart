import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ClientConnectionDialog extends StatefulWidget {
  const ClientConnectionDialog({
    super.key,
    required this.onCancel,
    required this.onCreateServer,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final Future<(WebSocketChannel, MessageChannel)> Function(String ip, int port) onCreateServer;
  final void Function(MessageChannel channel, ClientDatabaseArgs args) onConfirm;

  @override
  State<ClientConnectionDialog> createState() => _ClientConnectionDialogState();

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onCancel,
    required Future<(WebSocketChannel, MessageChannel)> Function(String ip, int port) onCreateServer,
    required void Function(MessageChannel channel, ClientDatabaseArgs args) onConfirm,
  }) {
    return showDialog(
      context: context,
      dismissWithEsc: false,
      builder: (context) => ClientConnectionDialog(
        onCancel: onCancel,
        onCreateServer: onCreateServer,
        onConfirm: onConfirm,
      ),
    );
  }
}

class _ClientConnectionDialogState extends State<ClientConnectionDialog> {
  static const flex = [1, 1, 1, 1, 2];
  final focusNodes = List.generate(5, (_) => FocusNode());
  final controllers = List.generate(5, (_) => TextEditingController());

  var parentIp = null as String?;
  var port = null as int?;

  var isConnecting = false;
  var testMessage = null as String?;
  var testMessageColor = null as Color?;
  var loadedWebsocketChannel = null as WebSocketChannel?;
  var loadedMessageChannel = null as MessageChannel?;

  void reset() {
    if (!context.mounted) return;
    setState(() {
      testMessage = null;
      testMessageColor = null;
      isConnecting = false;

      loadedWebsocketChannel?.sink.close();
      loadedWebsocketChannel = null;
      loadedMessageChannel = null;
    });
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
        if (loadedWebsocketChannel == null)
          Button(
            onPressed: () async {
              parentIp = controllers.take(4).map((s) => s.text.trim()).join(".");
              port = int.parse(controllers.last.text.trim());

              final ipAddress = "$parentIp:$port";
              reset();

              if (!context.mounted) return;

              try {
                final (websocket, message) = await widget.onCreateServer(parentIp!, port!);
                setState(() {
                  testMessage = "Successfully connected to $ipAddress.";
                  testMessageColor = Colors.green;
                  isConnecting = false;

                  loadedWebsocketChannel = websocket;
                  loadedMessageChannel = message;
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
            onPressed: () {
              if (loadedWebsocketChannel != null && loadedMessageChannel != null) {
                widget.onConfirm(
                  loadedMessageChannel!,
                  ClientDatabaseArgs(
                    parentIp: parentIp!,
                    port: port!,
                    webSocketChannel: loadedWebsocketChannel!,
                    messageChannel: loadedMessageChannel!,
                    close: () async {
                      await loadedWebsocketChannel!.sink.close(0);
                    },
                  ),
                );
              }
            },
            child: const Text("OK"),
          ),
      ],
    );
  }
}
