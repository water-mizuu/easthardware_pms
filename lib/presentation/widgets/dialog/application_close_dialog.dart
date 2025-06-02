import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ApplicationCloseDialog extends StatelessWidget {
  const ApplicationCloseDialog({super.key, required this.onSuccess});

  final void Function() onSuccess;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('Close Application'),
      content: const Text('Are you sure you want to close this window?'),
      actions: [
        Button(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.blue),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
          ),
          autofocus: true,
          child: const Text('No'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        Button(
          onPressed: () async {
            Navigator.of(context).pop();

            onSuccess();
          },
          child: const Text('Yes'),
        ),
      ],
    );
  }

  static Future<void> show(BuildContext context, {required VoidCallback onSuccess}) async {
    await showSingleDialog(
      context,
      (context) => ApplicationCloseDialog(onSuccess: onSuccess),
    );
  }
}
