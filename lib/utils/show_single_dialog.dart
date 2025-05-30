import 'package:fluent_ui/fluent_ui.dart';

bool _isDialogShowing = false;

Future<void> showSingleDialog(
  BuildContext context,
  Widget Function(BuildContext) dialog, {
  bool barrierDismissible = false,
  bool dismissWithEsc = true,
}) async {
  // if (_isDialogShowing) {
  //   if (Navigator.canPop(context)) {
  //     Navigator.of(context).pop();
  //   }
  // }

  _isDialogShowing = true;
  await showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    dismissWithEsc: dismissWithEsc,
    builder: dialog,
  );
  _isDialogShowing = false;
}
