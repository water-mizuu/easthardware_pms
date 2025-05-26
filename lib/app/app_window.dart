import 'dart:async';

import 'package:easthardware_pms/app/app.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class AppWindow extends StatefulWidget {
  const AppWindow({super.key});

  @override
  State<AppWindow> createState() => _AppWindowState();
}

/// This widget handles only the window. Events like close, minimize, maximize, etc.
class _AppWindowState extends State<AppWindow> with WindowListener {
  late final GlobalKey<NavigatorState> rootKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    WindowManagerPlus.current.addListener(this);
    unawaited(_init());
  }

  @override
  void dispose() {
    WindowManagerPlus.current.removeListener(this);

    super.dispose();
  }

  @override
  void onWindowEvent(String eventName, [int? windowId]) {
    if (kDebugMode) {
      print('Window event: $eventName, windowId: $windowId');
    }
  }

  @override
  void onWindowFocus([int? windowId]) {
    /// Apparently required for when hiding the window before start.
    setState(() {});
  }

  @override
  void onWindowClose([int? windowId]) async {
    final isPreventClose = await WindowManagerPlus.current.isPreventClose();
    if (!mounted) return;

    if (isPreventClose) {
      showDialog(
        context: rootKey.currentContext!,
        builder: (context) {
          return ContentDialog(
            title: Text('Close Application'),
            content: Text('Are you sure you want to close this window?'),
            actions: [
              Button(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.blue),
                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                ),
                autofocus: true,
                child: Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              Button(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await WindowManagerPlus.current.destroy();
                },
                child: Text('Yes'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  App build(BuildContext context) => App(rootKey: rootKey);

  Future<void> _init() async {
    await WindowManagerPlus.current.setPreventClose(true);

    setState(() {});
  }
}
