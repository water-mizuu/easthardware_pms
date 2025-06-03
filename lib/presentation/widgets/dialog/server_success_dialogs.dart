import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// Dialog shown when client connection is established
class ClientConnectionSuccessDialog extends StatelessWidget {
  const ClientConnectionSuccessDialog({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text("Client Connected"),
      content: const Column(
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
          onPressed: onCancel,
          child: const Text("Cancel"),
        ),
        Button(
          onPressed: onConfirm,
          child: const Text("OK"),
        ),
      ],
    );
  }

  /// Shows the client connection success dialog
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
  }) {
    return showSingleDialog(
      context,
      (context) => ClientConnectionSuccessDialog(
        onCancel: onCancel,
        onConfirm: onConfirm,
      ),
      dismissWithEsc: false,
    );
  }
}

/// Dialog shown when server is started successfully
class ServerStartedSuccessDialog extends StatelessWidget {
  const ServerStartedSuccessDialog({
    super.key,
    required this.serverIp,
    required this.port,
    required this.onGoBack,
    required this.onConfirm,
  });
  final String serverIp;
  final int port;
  final VoidCallback onGoBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    const flex = [1, 1, 1, 1, 2];
    final ipParts = serverIp.split(".");
    final addressParts = [...ipParts, port.toString()];

    return ContentDialog(
      title: const Text("Server Started"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text.rich(
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
                    readOnly: true,
                  ),
                ),
              ],
            ].withSpacing(() => const SizedBox(width: 4.0)),
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: onGoBack,
          child: const Text("Go back"),
        ),
        Button(
          onPressed: onConfirm,
          child: const Text("OK"),
        ),
      ],
    );
  }

  /// Shows the server started success dialog
  static Future<void> show({
    required BuildContext context,
    required String serverIp,
    required int port,
    required VoidCallback onGoBack,
    required VoidCallback onConfirm,
  }) {
    return showSingleDialog(
      context,
      (context) => ServerStartedSuccessDialog(
        serverIp: serverIp,
        port: port,
        onGoBack: onGoBack,
        onConfirm: onConfirm,
      ),
      dismissWithEsc: false,
    );
  }
}
