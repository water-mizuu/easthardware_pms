import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class IsFullScreen {
  const IsFullScreen({required this.isFullScreen});

  final bool isFullScreen;

  static Widget provider({
    required Widget child,
  }) {
    return _IsFullScreenProvider(child: child);
  }
}

class _IsFullScreenProvider extends StatefulWidget {
  const _IsFullScreenProvider({required this.child});

  final Widget child;

  @override
  State<_IsFullScreenProvider> createState() => _IsFullScreenProviderState();
}

class _IsFullScreenProviderState extends State<_IsFullScreenProvider> with WindowListener {
  bool isFullScreen = false;

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
      isFullScreen = true;
    });
  }

  /// Emitted when the window exits from a maximized state.
  @override
  void onWindowUnmaximize([int? windowId]) {
    setState(() {
      isFullScreen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: IsFullScreen(isFullScreen: isFullScreen),
      child: widget.child,
    );
  }
}

extension IsFullScreenExtension on BuildContext {
  /// Returns the current [IsFullScreen] state.
  bool get isFullScreen => read<IsFullScreen>().isFullScreen;

  /// Returns the current [IsFullScreen] state with listening enabled.
  bool watchIsFullScreen() => watch<IsFullScreen>().isFullScreen;
}
