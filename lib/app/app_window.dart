import 'dart:async';

import 'package:easthardware_pms/app/app.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/application_close_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    unawaited(() async {
      await WindowManagerPlus.current.setPreventClose(true);
      if (!mounted) return;

      setState(() {});
    }());
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
    /// If the router is not mounted, then it should mean that
    ///   the application is not running. So just close it.
    final innerContext = rootWidgetKey.currentContext;
    if (innerContext == null || !mounted) return _exit();

    /// Now, we only want to proceed if the user has not set the
    ///   prevent close option to true.
    final isPreventClose = await WindowManagerPlus.current.isPreventClose();
    if (!isPreventClose || !mounted || !innerContext.mounted) return _exit();

    /// If there is no user authenticated, we can safely exit the application.
    final currentUser = innerContext.read<AuthenticationBloc>().state.user;
    if (currentUser == null) return _exit();

    /// If the user is authenticated, we show a dialog to confirm the exit.
    if (innerContext.mounted) {
      await ApplicationCloseDialog.show(innerContext, onSuccess: _exit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}

void _exit() {
  Timer(const Duration(milliseconds: 100), () {
    print("Hi");
    WindowManagerPlus.current.destroy();
  });

  WindowManagerPlus.current.setPreventClose(false);
  WindowManagerPlus.current.close();
}
