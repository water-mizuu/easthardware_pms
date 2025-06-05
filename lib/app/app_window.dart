import 'dart:async';

import 'package:easthardware_pms/app/app.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/presentation/views/authentication/login_page.dart';
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
    try {
      /// If the router is not mounted, then it should mean that
      ///   the application is not running. So just close it.
      final innerContext = rootWidgetKey.currentContext;
      if (innerContext == null || !mounted) _exit();

      /// Now, we only want to proceed if the user has not set the
      ///   prevent close option to true.
      final isPreventClose = await WindowManagerPlus.current.isPreventClose();
      if (!isPreventClose || !mounted || !innerContext.mounted) _exit();

      /// If there is no user authenticated, we can safely exit the application.
      final currentUser = innerContext.read<AuthenticationBloc>().state.user;
      if (currentUser == null) _exit();

      /// If the user is authenticated, we need to prep the context
      ///   for the dialog.
      final exitCompleter = Completer<bool>();
      ApplicationCloseDialog.show(
        innerContext,
        onSuccess: () => exitCompleter.complete(true),
        onCancel: () => exitCompleter.complete(false),
      );
      final didUserConfirmExit = await exitCompleter.future;
      if (!didUserConfirmExit) return;

      assert(innerContext.mounted, "The router should still be mounted at this point.");
      if (!innerContext.mounted) return;

      /// If the user confirmed the exit, we can safely close the application.
      ///   We also need to add a logout event to the logs.
      await _addLogoutEvent(innerContext);
      _exit();
    } on UnreachableError {
      /// Do nothing, as this is expected.
    }
  }

  @override
  Widget build(BuildContext context) {
    return const App();
  }
}

Future<void> _addLogoutEvent(BuildContext context) async {
  final user = context.read<AuthenticationBloc>().state.user;
  if (user == null) return;

  /// Add a logout event to the logs.
  context.read<UserLogListBloc>().add(AddLogoutEvent(user));
}

Never _exit() {
  Timer(const Duration(milliseconds: 100), () {
    WindowManagerPlus.current.destroy();
  });

  WindowManagerPlus.current.setPreventClose(false);
  WindowManagerPlus.current.close();

  throw UnreachableError();
}
