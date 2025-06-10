import 'package:easthardware_pms/domain/backend/enum/database_mode.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// Dialog for selecting between server and client mode
class ServerModeSelectionDialog extends StatelessWidget {
  const ServerModeSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
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
  }

  /// Shows the dialog and returns the selected mode
  static Future<DatabaseMode?> show(BuildContext context) {
    return showDialog<DatabaseMode>(
      useRootNavigator: true,
      context: context,
      dismissWithEsc: false,
      builder: (context) => const ServerModeSelectionDialog(),
    );
  }
}
