// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:easthardware_pms/app/app_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

Future<(T?, (Object, StackTrace)?)> runAsync<T>(Future<T> future) async {
  try {
    return (await future, null);
  } catch (e, s) {
    return (null, (e, s));
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Load the window manager plus plugin.
  if ((!kIsWeb) && (Platform.isWindows || Platform.isMacOS)) {
    const startSize = Size(960, 640);
    const minimumSize = Size(800, 600);

    final id = args.isEmpty ? 0 : int.tryParse(args[0]) ?? 0;
    final (_) = await runAsync(WindowManagerPlus.ensureInitialized(id));
    final options = WindowOptions(
      size: startSize,
      minimumSize: minimumSize,
      center: true,
      skipTaskbar: false,
    );

    WindowManagerPlus.current.waitUntilReadyToShow(options, () async {
      await WindowManagerPlus.current.setTitle('My App');
      if (Platform.isWindows) {
        await WindowManagerPlus.current.setAlwaysOnBottom(false);
      }

      await WindowManagerPlus.current.setTitleBarStyle(TitleBarStyle.hidden);
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    });
  }

  /// Current idea:
  ///   1. scan for all ips in the subnetwork.
  ///   2. check if the ip is reachable (try to establish a connection at specific ports.)
  ///   3. if reachable, connect to the server as needed.
  ///     3.1 save the mac address of the server.
  ///   4. if not reachable, check any of the ips if their mac address matches the saved if any.
  ///     4.1 if yes, connect to the server as needed.
  ///     4.2 if no, check if the server is reachable at the saved ip.
  ///   5. if nothing works, prompt the user to enter the ip address of the server.

  runApp(AppWindow());
}
