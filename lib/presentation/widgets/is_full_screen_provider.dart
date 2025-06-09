import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class IsFullScreen {
  const IsFullScreen({required this.isFullScreen});

  final bool isFullScreen;

  /// Provides a way to access the current full-screen state of the
  ///   application synchronously. Use [context.isFullScreen] or [IsFullScreen.builder]
  ///   to access the state in the widget tree.
  static Widget provider({required Widget child}) {
    return _IsFullScreenProvider(child: child);
  }

  /// A builder that provides the current full-screen state of the application.
  ///   This is useful for widgets that need to react to the full-screen state.
  static Widget builder({
    required Widget Function(
      BuildContext context,
      bool isFullScreen,
      Widget? child,
    ) builder,
    Widget? child,
  }) {
    return Consumer<IsFullScreen>(
      builder: (context, obj, child) => builder(context, obj.isFullScreen, child),
      child: child,
    );
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

  @override
  void onWindowEnterFullScreen([int? windowId]) {
    setState(() {
      isFullScreen = true;
    });
  }

  @override
  void onWindowLeaveFullScreen([int? windowId]) {
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
