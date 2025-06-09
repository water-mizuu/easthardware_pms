import 'dart:async';

import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';

class LogOutDialog extends StatelessWidget {
  const LogOutDialog({
    this.onConfirmed,
    this.onCancelled,
    super.key,
  });

  final VoidCallback? onConfirmed;
  final VoidCallback? onCancelled;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        FilledButton(
          child: const Text('Cancel'),
          onPressed: () {
            onCancelled?.call();
            Navigator.of(context).pop();
          },
        ),
        Button(
          child: const Text('Log Out'),
          onPressed: () {
            // Handle log out logic here
            onConfirmed?.call();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  static Future<bool> show(BuildContext context) {
    final result = Completer<bool>.sync();
    showSingleDialog(context, (context) {
      return LogOutDialog(
        onConfirmed: () {
          result.complete(true);
        },
        onCancelled: () {
          result.complete(false);
        },
      );
    });

    return result.future;
  }
}
