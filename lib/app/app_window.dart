import 'dart:async';
import 'dart:io';

import 'package:easthardware_pms/app/app.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show TextButton;
import 'package:provider/provider.dart';
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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TitleBar(
        child: App(rootKey: rootKey),
      ),
    );
  }

  Future<void> _init() async {
    await WindowManagerPlus.current.setPreventClose(true);

    setState(() {});
  }
}

class TitleBar extends StatefulWidget {
  const TitleBar({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<TitleBar> createState() => _TitleBarState();

  static bool of(BuildContext context) {
    try {
      context.read<_TitleBarState>();

      return true;
    } catch (e) {
      return false;
    }
  }
}

class _TitleBarState extends State<TitleBar> with WindowListener {
  bool isMaximized = false;

  Future<void> _maximizeOrUnmaximize() async {
    if (isMaximized) {
      await WindowManagerPlus.current.unmaximize();
    } else {
      await WindowManagerPlus.current.maximize();
    }
  }

  @override
  void initState() {
    super.initState();

    WindowManagerPlus.current.addListener(this);
  }

  @override
  void dispose() {
    WindowManagerPlus.current.removeListener(this);

    super.dispose();
  }

  /// Emitted when window is maximized.
  @override
  void onWindowMaximize([int? windowId]) {
    setState(() {
      isMaximized = true;
    });
  }

  /// Emitted when the window exits from a maximized state.
  @override
  void onWindowUnmaximize([int? windowId]) {
    setState(() {
      isMaximized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InheritedProvider<_TitleBarState>.value(
      value: this,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            child: _titleBar(),
          )
        ],
      ),
    );
  }

  SizedBox _titleBar() {
    return SizedBox(
      height: 32.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (_) async {
                await WindowManagerPlus.current.startDragging();
              },
              onDoubleTap: _maximizeOrUnmaximize,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          if (Platform.isWindows) ...[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: () async {
                await WindowManagerPlus.current.minimize();
              },
              child: Text('Minimize'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: _maximizeOrUnmaximize,
              child: Text(isMaximized ? 'Unmaximize' : 'Maximize'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith((state) {
                  if (state.contains(WidgetState.pressed)) {
                    return Colors.red.withAlpha(192);
                  } else if (state.contains(WidgetState.hovered)) {
                    return Colors.red.withAlpha(128);
                  } else if (state.contains(WidgetState.focused)) {
                    return Colors.red.withAlpha(128);
                  }
                  return Colors.transparent;
                }),
              ),
              onPressed: () async {
                await WindowManagerPlus.current.close();
              },
              child: Text('Close'),
            ),
          ]
        ],
      ),
    );
  }
}
