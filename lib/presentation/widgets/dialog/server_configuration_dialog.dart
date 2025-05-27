import 'package:easthardware_pms/backend/extension_types/shelf_server.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

/// Dialog for configuring server information (port number)
class ServerConfigurationDialog extends StatefulWidget {
  const ServerConfigurationDialog({
    super.key,
    this.defaultPort,
    required this.onStartServer,
    required this.onCancel,
    required this.onSuccess,
  });
  final String? defaultPort;
  final Future<(ShelfServer, ShelfServer, Stream<ServerEvent>)> Function(int port) onStartServer;
  final VoidCallback onCancel;
  final Function(ShelfServer landing, ShelfServer webSocket, Stream<ServerEvent>) onSuccess;

  @override
  State<ServerConfigurationDialog> createState() => _ServerConfigurationDialogState();

  static Future<void> show({
    required BuildContext context,
    String? defaultPort,
    required Future<(ShelfServer, ShelfServer, Stream<ServerEvent>)> Function(int port)
        onStartServer,
    required VoidCallback onCancel,
    required Function(ShelfServer landing, ShelfServer webSocket, Stream<ServerEvent>) onSuccess,
  }) {
    return showDialog(
      context: context,
      dismissWithEsc: false,
      builder: (context) => ServerConfigurationDialog(
        onStartServer: onStartServer,
        defaultPort: defaultPort,
        onCancel: onCancel,
        onSuccess: onSuccess,
      ),
    );
  }
}

class _ServerConfigurationDialogState extends State<ServerConfigurationDialog> {
  late final TextEditingController portController;
  final formKey = GlobalKey<FormState>();

  var isConnecting = false;
  String? testMessage;
  Color? testMessageColor;

  @override
  void initState() {
    super.initState();
    portController = TextEditingController(text: widget.defaultPort);
  }

  @override
  void dispose() {
    portController.dispose();
    super.dispose();
  }

  void _resetTestState() {
    setState(() {
      testMessage = null;
      isConnecting = false;
    });
  }

  Future<void> _startServer() async {
    if (isConnecting) return;

    setState(() {
      isConnecting = true;
      testMessage = null;
    });

    try {
      final port = int.parse(portController.text);
      if (port < 2000 || port > 65535) {
        throw Exception("Port number must be between 2000 and 65535.");
      }

      final (landing, webSocket, stream) = await widget.onStartServer(port);

      if (!mounted) return;

      Navigator.of(context).pop();
      widget.onSuccess(landing, webSocket, stream);
    } catch (e) {
      if (kDebugMode) {
        print('Server start error: $e');
      }

      if (!mounted) return;

      setState(() {
        isConnecting = false;
        testMessage = "Failed to start server: $e";
        testMessageColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              onChanged: (value) => _resetTestState(),
            ),
            if (isConnecting) ...[
              const SizedBox(height: 12.0),
              const ProgressRing(
                strokeWidth: 2.0,
                value: null,
              ),
              const Text(
                "Starting server...",
                style: TextStyle(color: Colors.black),
              ),
            ],
            if (testMessage != null) ...[
              const SizedBox(height: 12.0),
              Text(
                testMessage!,
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
            widget.onCancel();
          },
          child: const Text("Cancel"),
        ),
        Button(
          onPressed: _startServer,
          child: const Text("Start server"),
        ),
      ],
    );
  }
}
