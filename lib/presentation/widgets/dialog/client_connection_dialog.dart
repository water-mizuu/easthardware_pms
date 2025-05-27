import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/utils/try_future.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ClientConnectionDialog extends StatefulWidget {
  const ClientConnectionDialog({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final void Function(String address, int port) onConfirm;

  @override
  State<ClientConnectionDialog> createState() => _ClientConnectionDialogState();

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onCancel,
    required void Function(String address, int port) onConfirm,
  }) {
    return showDialog(
      context: context,
      dismissWithEsc: false,
      builder: (context) => ClientConnectionDialog(
        onCancel: onCancel,
        onConfirm: onConfirm,
      ),
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

  void reset() {
    if (!context.mounted) return;
    setState(() {
      testMessage = null;
      testMessageColor = null;
      isConnecting = false;

      address = null;
      port = null;
    });
  }

  Future<void> _testConnection() async {
    reset();

    address = controllers.take(4).map((s) => s.text.trim()).join(".");
    port = int.parse(controllers.last.text.trim());

    final target = "$address:$port";
    final uri = Uri.parse("http://$target/ping");
    final (response, error) = await http.get(uri).tryCatch();
    if (error case (final Object error, final StackTrace stackTrace)) {
      if (kDebugMode) {
        print("Failed to ping $target: $error");
        print(stackTrace);
      }

      setState(() {
        testMessage = "Failed to connect to $target.";
        testMessageColor = Colors.red;
        isConnecting = false;
      });
      return;
    }

    if (response!.statusCode != 200) {
      if (kDebugMode) {
        print("Failed to ping $target: ${response.statusCode}");
      }

      setState(() {
        testMessage = "Failed to connect to $target.";
        testMessageColor = Colors.red;
        isConnecting = false;
      });
      return;
    }

    setState(() {
      testMessage = "Successfully connected to $target.";
      testMessageColor = Colors.green;
      isConnecting = false;
    });
  }

  Future<void> _confirm() async {
    if (address case final address?) {
      if (port case final port?) {
        widget.onConfirm(address, port);
      }
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
