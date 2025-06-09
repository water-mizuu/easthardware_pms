import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ApplicationCloseDialog extends StatelessWidget {
  const ApplicationCloseDialog({
    super.key,
    this.onSuccess,
    this.onCancel,
  });

  final void Function()? onSuccess;
  final void Function()? onCancel;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('Close Application'),
      content: const Text('Are you sure you want to close this window?'),
      actions: [
        FilledButton(
          autofocus: true,
          child: const Text('No'),
          onPressed: () {
            Navigator.of(context).pop();

            onCancel?.call();
          },
        ),
        Button(
          onPressed: () async {
            Navigator.of(context).pop();

            onSuccess?.call();
          },
          child: const Text('Yes'),
        ),
      ],
    );
  }

  static Future<void> show(
    BuildContext context, {
    required VoidCallback? onSuccess,
    required VoidCallback? onCancel,
  }) async {
    await showSingleDialog(
      context,
      (context) => ApplicationCloseDialog(onSuccess: onSuccess, onCancel: onCancel),
    );
  }
}
