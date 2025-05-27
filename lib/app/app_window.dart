import 'dart:async';

import 'package:easthardware_pms/app/app.dart';
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class AppWindow extends StatefulWidget {
  const AppWindow({super.key});

  @override
  State<AppWindow> createState() => _AppWindowState();
}

/// This widget handles only the window. Events like close, minimize, maximize, etc.
class _AppWindowState extends State<AppWindow> with WindowListener {
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
  void onWindowFocus([int? windowId]) {
    /// Apparently required for when hiding the window before start.
    setState(() {});
  }

  @override
  Future<void> onWindowClose([int? windowId]) async {
    final isPreventClose = await WindowManagerPlus.current.isPreventClose();
    if (!mounted) return;

    if (isPreventClose) {
      await showDialog<void>(
        context: rootNavigatorKey.currentContext!,
        builder: (context) {
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
                  await WindowManagerPlus.current.destroy();
                },
                child: const Text('Yes'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const App();
  }

  Future<void> _init() async {
    await WindowManagerPlus.current.setPreventClose(true);

    setState(() {});
  }
}
