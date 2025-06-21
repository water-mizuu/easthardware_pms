import 'dart:async';

import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:fluent_ui/fluent_ui.dart';

void showNotification({
  required String title,
  required String message,
  InfoBarSeverity severity = InfoBarSeverity.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final innerContext = overlayWidgetKey.currentContext;
  if (innerContext == null) {
    printBoxed(
      "Cannot show notification: No context available.",
      "showNotification",
    );
    return; // No context available, cannot show notification
  }
  unawaited(displayInfoBar(
    innerContext,
    duration: duration,
    alignment: Alignment.bottomCenter,
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
  ));
}

extension ShowNotificationHelper on void Function({
  required String title,
  required String message,
  InfoBarSeverity severity,
  Duration duration,
}) {
  // /// ![Info InfoBar](https://docs.microsoft.com/en-us/windows/uwp/design/controls-and-patterns/images/infobar-default-hyperlink.png)
  // info,

  // /// ![Warning InfoBar](https://docs.microsoft.com/en-us/windows/uwp/design/controls-and-patterns/images/infobar-warning-title-message.png)
  // warning,

  // /// ![Error InfoBar](https://docs.microsoft.com/en-us/windows/uwp/design/controls-and-patterns/images/infobar-error-no-close.png)
  // error,

  // /// ![Success InfoBar](https://docs.microsoft.com/en-us/windows/uwp/design/controls-and-patterns/images/infobar-success-content-wrapping.png)
  // success,

  void info({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    this(
      title: title,
      message: message,
      severity: InfoBarSeverity.info,
      duration: duration,
    );
  }

  void warning({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    this(
      title: title,
      message: message,
      severity: InfoBarSeverity.warning,
      duration: duration,
    );
  }

  void error({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    this(
      title: title,
      message: message,
      severity: InfoBarSeverity.error,
      duration: duration,
    );
  }

  void success({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    this(
      title: title,
      message: message,
      severity: InfoBarSeverity.success,
      duration: duration,
    );
  }
}
