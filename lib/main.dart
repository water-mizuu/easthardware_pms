// ignore_for_file: avoid_print

import 'dart:async';

import 'package:easthardware_pms/app/app.dart';
import 'package:fluent_ui/fluent_ui.dart';

Future<(T?, (Object, StackTrace)?)> runAsync<T>(Future<T> future) async {
  try {
    return (await future, null);
  } catch (e, s) {
    return (null, (e, s));
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// Current idea:
  ///   1. scan for all ips in the subnetwork.
  ///   2. check if the ip is reachable (try to establish a connection at specific ports.)
  ///   3. if reachable, connect to the server as needed.
  ///     3.1 save the mac address of the server.
  ///   4. if not reachable, check any of the ips if their mac address matches the saved if any.
  ///     4.1 if yes, connect to the server as needed.
  ///     4.2 if no, check if the server is reachable at the saved ip.
  ///   5. if nothing works, prompt the user to enter the ip address of the server.
  // var isolate = Isolate.spawn((rootIsolateToken) async {
  //   BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

  //   var stopwatch = Stopwatch()..start();
  //   var futures = <Future>[];
  //   var successes = [];
  //   print("Start pinging");
  //   for (var i = 1; i < 256; ++i) {
  //     for (var j = 1; j < 256; ++j) {
  //       var ip = "192.168.$i.$j";
  //       var future = runAsync(() async {
  //         try {
  //           var socket = await Socket.connect(ip, 80, timeout: const Duration(seconds: 1));
  //           successes.add(ip);
  //           socket.destroy();
  //         } catch (e) {
  //           // ignore
  //         }
  //       });
  //       futures.add(future);
  //     }
  //   }

  //   await Future.wait(futures);
  //   print("Ping completed");
  //   print("Successes: $successes");
  //   stopwatch.stop();
  //   print("Elapsed time: ${stopwatch.elapsed.inSeconds} seconds");
  // }, RootIsolateToken.instance!);

  runApp(App());
}
