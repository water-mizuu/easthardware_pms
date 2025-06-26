import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';

class BackupDeleteDialog extends StatelessWidget {
  const BackupDeleteDialog({
    super.key,
    this.onSuccess,
    this.onCancel,
  });

  final void Function()? onSuccess;
  final void Function()? onCancel;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('Delete Backup'),
      content: const Text('Are you sure you want to delete this backup?'),
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

  static Future<void> show({
    required VoidCallback? onSuccess,
    required VoidCallback? onCancel,
  }) async {
    await showSingleDialog(
      (_) => BackupDeleteDialog(onSuccess: onSuccess, onCancel: onCancel),
    );
  }
}
