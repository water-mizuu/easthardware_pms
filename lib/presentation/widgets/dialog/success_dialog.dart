import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';

class SuccessDialog extends StatelessWidget {
  const SuccessDialog({
    super.key,
    required this.title,
    required this.body,
    this.onSuccess,
    this.onCancel,
  });

  final String title;
  final String body;
  final void Function()? onSuccess;
  final void Function()? onCancel;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(title),
      content: Text(body),
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
    required String title,
    required String body,
    VoidCallback? onSuccess,
    VoidCallback? onCancel,
  }) async {
    await showSingleDialog(
      context,
      (context) => SuccessDialog(
        title: title,
        body: body,
        onSuccess: onSuccess,
        onCancel: onCancel,
      ),
    );
  }
}

extension SuccessDialogExtension on BuildContext {
  Future<void> showSuccessDialog({
    required String title,
    required String body,
    VoidCallback? onSuccess,
    VoidCallback? onCancel,
  }) async {
    return SuccessDialog.show(
      this,
      title: title,
      body: body,
      onSuccess: onSuccess,
      onCancel: onCancel,
    );
  }
}
