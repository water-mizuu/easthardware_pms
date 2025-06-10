import 'dart:async';

import 'package:easthardware_pms/app/app.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/presentation/views/authentication/login_page.dart';
import 'package:easthardware_pms/presentation/widgets/dialog/application_close_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/try_future.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
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
      final (isPreventClose, err) = await WindowManagerPlus.current.isPreventClose().tryCatch();
      if (isPreventClose == false || err != null || !mounted || !innerContext.mounted) _exit();

      /// If there is no user authenticated, we can safely exit the application.
      final currentUser = innerContext.read<AuthenticationBloc>().state.user;
      if (currentUser == null) await _exitGracefully(innerContext);
      if (!innerContext.mounted) _exit();

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
      await _exitGracefully(innerContext);
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

  /// Add a logout event to the user log list bloc.
  context.read<UserLogListBloc>().add(AddLogoutEvent(user));
}

/// This function tries to close the servers.
///   If it detects that the servers are not closed after 20 seconds,
///   it will show a dialog to the user asking them to force close the application
///   if they want to.
Future<void> _closeServers(BuildContext context) async {
  if (kDebugMode) {
    printBoxed(
      "Closing the application...\nThe database args are: ${context.read<ServerBloc>().state.databaseArgs}",
      "Application Close",
    );
  }

  var dialogHasShown = false;
  final timer = Timer(
    const Duration(seconds: 1),
    () async {
      if (!context.mounted) return;

      /// If the router is mounted, even after one second, we need
      ///   to let the user know that the application is closing.

      final allowForceKill = ValueNotifier(false);
      final timer = Timer(const Duration(seconds: 4), () {
        if (!context.mounted) return;
        allowForceKill.value = true;
      });
      dialogHasShown = true;
      await showDialog(
        useRootNavigator: true,
        context: context,
        builder: (context) {
          return ValueListenableBuilder(
            valueListenable: allowForceKill,
            builder: (context, value, _) {
              return ContentDialog(
                title: const Text("Closing Application"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Spacing.v12,
                    const Center(child: ProgressRing()),
                    Spacing.v16,
                    const Center(
                      child: Text(
                        "Closing the connections to the server... " //
                        "It may take a while.",
                      ),
                    ),
                    if (value)
                      Text(
                        "It's taking a while. You can force close the application.",
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
                actions: !value
                    ? null
                    : [const FilledButton(onPressed: _exit, child: Text("End Process"))],
              );
            },
          );
        },
      );

      timer.cancel();
    },
  );

  /// Close the existing servers.
  final serverState = context.read<ServerBloc>().state;
  final databaseArgs = serverState.databaseArgs!;

  if (databaseArgs is ServerDatabaseArgs) {
    final (_, error) = await (
      databaseArgs.landingServer.close(),
      databaseArgs.webSocketServer.close(),
    ).wait.tryCatch();

    if (error != null) {
      if (kDebugMode) {
        printBoxed(
          "Failed to close the server:\n$error",
          "Server Close Error",
        );
      }
      return;
    }
  } else if (databaseArgs is ClientDatabaseArgs) {
    final (_, error) = await databaseArgs.close!.call().tryCatch();
    if (error != null) {
      if (kDebugMode) {
        printBoxed(
          "Failed to close the client connection:\n$error",
          "Client Close Error",
        );
      }
      return;
    }
  }

  timer.cancel();
  if (dialogHasShown) {
    if (!context.mounted) return;

    Navigator.of(context).pop();
  }
}

Never _exit() {
  Timer(const Duration(milliseconds: 100), () => WindowManagerPlus.current.destroy());

  WindowManagerPlus.current.setPreventClose(false);
  WindowManagerPlus.current.close();

  throw UnreachableError();
}

Future<Never> _exitGracefully(BuildContext context) async {
  await _addLogoutEvent(context);
  if (!context.mounted) _exit();

  await _closeServers(context);
  if (!context.mounted) _exit();

  _exit();
}
