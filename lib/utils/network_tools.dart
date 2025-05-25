import "dart:async";
import "dart:isolate";

import "package:easthardware_pms/utils/message_channel.dart";
import "package:easthardware_pms/utils/parallelism.dart";
import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:network_info_plus/network_info_plus.dart";
import "package:network_tools/network_tools.dart";
import "package:path_provider/path_provider.dart";

/// The receive port for the network tools isolate.
///   This is the only way to communicate with the isolate.
MessageChannel? _isolateMessageChannel;

/// Does the necessary setup to allow running the network tools over in a separate isolate.
/// This function must be called from the root isolate.
Future<void> initializeNetworkTools() async {
  assert(RootIsolateToken.instance != null, "This function must be called from the root isolate.");

  var deviceIp = await NetworkInfo().getWifiIP().then((p) => p!);
  if (kDebugMode) {
    print("Device IP: $deviceIp");
  }

  /// Initialize the network tools in the root isolate too.
  var appDocDirectory = await getApplicationDocumentsDirectory();
  if (kDebugMode) {
    print("Application Document Directory: ${appDocDirectory.path}");
  }

  var networkToolsReceivePort = ReceivePort().hostListener();
  NamedSendPort networkToolsSendPort;

  await configureNetworkTools(appDocDirectory.path);
  await Isolate.spawn(_networkTools, (
    networkToolsReceivePort.sendPort,
    RootIsolateToken.instance!,
    deviceIp,
  ));
  networkToolsSendPort = await networkToolsReceivePort.next<NamedSendPort>("sendPort");

  _isolateMessageChannel = MessageChannel(
    networkToolsReceivePort,
    networkToolsSendPort,
  );

  if (kDebugMode) {
    print("Successfully initialized network tools.");
  }
}

/// Scans the local network for active hosts, returning a list of tuples
///   containing the device name and IP address.
Future<List<(Future<String>, String)>> scanIps() async {
  assert(_isolateMessageChannel != null, "Network tools not initialized.");

  var result = await _isolateMessageChannel!.invoke<List<SendableActiveHost>>("scan_ips");

  return [
    for (var sendableActiveHost in result)
      (
        ActiveHost.fromSendableActiveHost(sendableActiveHost: sendableActiveHost) //
            .deviceName
            .timeout(const Duration(seconds: 2))
            .catchError((_) => "Unnamed Device"),
        sendableActiveHost.address,
      ),
  ];
}

/// The process run by the isolate. After the initialization,
///   The isolate waits for the receivePort.
Future<void> _networkTools((SendPort, RootIsolateToken, String) payload) async {
  /// Isolate Initialization
  var (sendPort, token, deviceIp) = payload;
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  /// The local receive port within the isolate.
  var receivePort = ReceivePort().hostListener();
  sendPort.send(receivePort.sendPort);

  /// Necessary for the network tools to work in the separate isolate.
  var appDocDirectory = await getApplicationDocumentsDirectory();
  await configureNetworkTools(appDocDirectory.path);

  unawaited(() async {
    while (true) {
      final message = await receivePort.next("message");
      assert(
        message is List && message.first is String,
        "Messages should follow the format [String, ?List<Object?>? arguments]."
        " The failure of this assertion most likely means that a user tried "
        " to send a message to the isolate using the raw SendPort instead of "
        " the ServerChannel.",
      );

      if (message case ["scan_ips", _]) {
        var subnet = deviceIp.substring(0, deviceIp.lastIndexOf("."));
        var searcher = HostScannerService.instance.getAllSendablePingableDevices(subnet);
        var devices = [await for (var device in searcher) device];
        sendPort.send(devices);
      } else {
        throw StateError("Unrecognized message $message.");
      }
    }
  }());
}
