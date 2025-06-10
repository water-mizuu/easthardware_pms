import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

bool _isDialogShowing = false;

Future<void> showSingleDialog(
  Widget Function(BuildContext) dialog, {
  bool barrierDismissible = false,
  bool dismissWithEsc = true,
}) async {
  final context = rootWidgetKey.currentContext;
  if (context == null) {
    if (kDebugMode) {
      printBoxed(
        "No context available to show dialog. Ensure the app is initialized properly.",
        "showSingleDialog",
      );
    }
    return;
  }

  if (_isDialogShowing) {
    Navigator.of(context).pop();
  }

  _isDialogShowing = true;
  await showDialog<void>(
    useRootNavigator: true,
    context: context,
    barrierDismissible: barrierDismissible,
    dismissWithEsc: dismissWithEsc,
    builder: dialog,
  );
  _isDialogShowing = false;
}
