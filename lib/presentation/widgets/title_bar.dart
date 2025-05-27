import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons, TextButton;
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

const macOSTitleBarHeight = 28.0;
const windowsTitleBarHeight = 32.0;

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

  Future<void> _minimize() async {
    await WindowManagerPlus.current.minimize();
  }

  Future<void> _maximizeOrUnmaximize() async {
    if (isMaximized) {
      await WindowManagerPlus.current.unmaximize();
    } else {
      await WindowManagerPlus.current.maximize();
    }
  }

  Future<void> _close() async {
    await WindowManagerPlus.current.close();
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
    late final buttonStyle = TextButton.styleFrom(
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(),
    );

    return SizedBox(
      height: Platform.isMacOS ? macOSTitleBarHeight : windowsTitleBarHeight,
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
              style: buttonStyle,
              onPressed: _minimize,
              child: Icon(FluentIcons.chrome_minimize, size: 12.0),
            ),
            TextButton(
              style: buttonStyle,
              onPressed: _maximizeOrUnmaximize,
              child: Icon(
                isMaximized ? FluentIcons.chrome_restore : Icons.square_outlined,
                size: isMaximized ? 12.0 : 14.0,
              ),
            ),
            TextButton(
              style: buttonStyle,
              // style: buttonStyle.copyWith(
              //   overlayColor: WidgetStateProperty.resolveWith((state) {
              //     if (state.contains(WidgetState.pressed)) {
              //       return Colors.red.withAlpha(192);
              //     } else if (state.contains(WidgetState.hovered)) {
              //       return Colors.red.withAlpha(128);
              //     } else if (state.contains(WidgetState.focused)) {
              //       return Colors.red.withAlpha(128);
              //     }
              //     return Colors.transparent;
              //   }),
              // ),
              onPressed: _close,
              child: Icon(FluentIcons.chrome_close, size: 12.0),
            ),
          ]
        ],
      ),
    );
  }
}
