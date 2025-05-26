import 'dart:async';

import 'package:easthardware_pms/app/main_screen.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show AlertDialog, TextButton;
import 'package:window_manager_plus/window_manager_plus.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WindowListener {
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
    windowId ??= 0;

    if (kDebugMode) {
      print('Window event: $eventName, windowId: $windowId');
    }
  }

  @override
  void onWindowClose([int? windowId]) async {
    final isPreventClose = await WindowManagerPlus.current.isPreventClose();
    if (!mounted) return;

    if (isPreventClose) {
      showDialog(
        context: rootKey.currentContext!,
        builder: (context) {
          return AlertDialog(
            title: Text('Are you sure you want to close this window?'),
            actions: [
              TextButton(
                child: Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Yes'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await WindowManagerPlus.current.destroy();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  MainScreen build(BuildContext context) => MainScreen(rootKey: rootKey);

  Future<void> _init() async {
    await WindowManagerPlus.current.setPreventClose(true);

    setState(() {});
  }
}
