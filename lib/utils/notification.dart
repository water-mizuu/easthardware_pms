import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

Future<void> showNotification({
  required String title,
  required String message,
  InfoBarSeverity severity = InfoBarSeverity.info,
  Duration duration = const Duration(seconds: 3),
}) async {
  final innerContext = overlayWidgetKey.currentContext;
  if (innerContext == null) {
    if (kDebugMode) {
      printBoxed(
        "Cannot show notification: No context available.",
        "showNotification",
      );
    }
    return; // No context available, cannot show notification
  }
  displayInfoBar(
    innerContext,
    builder: (context, close) {
      return InfoBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
        severity: severity,
      );
    },
  );
}
