import 'package:easthardware_pms/presentation/bloc/server/server_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/server/server_state.dart';
import 'package:easthardware_pms/utils/message_channel.dart';
import 'package:fluent_ui/fluent_ui.dart';

sealed class ServerEvent {
  const ServerEvent();
}

class ServerChangeKey extends ServerEvent {
  const ServerChangeKey({required this.key});

  final GlobalKey<NavigatorState> key;
}

class ServerReset extends ServerEvent {
  const ServerReset();
}

class ServerInit extends ServerEvent {
  const ServerInit();
}

class ServerPromptingUserFromNull extends ServerEvent {
  const ServerPromptingUserFromNull();
}

class ServerLoadingClientFromPreferences extends ServerEvent {
  const ServerLoadingClientFromPreferences({
    required this.address,
    required this.popupToUser,
    required this.saveToPreferences,
  });

  final String address;
  final bool popupToUser;
  final bool saveToPreferences;
}

class ServerPromptingClientInformation extends ServerEvent {
  const ServerPromptingClientInformation();
}

class ServerClientConnectionEstablished extends ServerEvent {
  const ServerClientConnectionEstablished({
    required this.args,
    required this.channel,
    required this.popupToUser,
    required this.saveToPreferences,
  });

  final ClientDatabaseArgs args;
  final MessageChannel channel;
  final bool popupToUser;
  final bool saveToPreferences;
}

class ServerLoadingServerFromPreferences extends ServerEvent {
  const ServerLoadingServerFromPreferences({
    required this.port,
    this.popupToUser = true,
    this.saveToPreferences = false,
  });

  final int port;
  final bool popupToUser;
  final bool saveToPreferences;
}

class ServerPromptingServerInformation extends ServerEvent {
  const ServerPromptingServerInformation();
}

class ServerServerStarted extends ServerEvent {
  const ServerServerStarted({
    required this.args,
    required this.channel,
    required this.popupToUser,
    required this.saveToPreferences,
  });

  final ServerDatabaseArgs args;
  final MessageChannel channel;
  final bool popupToUser;
  final bool saveToPreferences;
}

class ServerSaveClientInformation extends ServerEvent {
  const ServerSaveClientInformation({required this.serverAddress});

  final String serverAddress;
}

class ServerSaveServerInformation extends ServerEvent {
  const ServerSaveServerInformation({required this.port});

  final int port;
}

class ServerDatabaseUpdated extends ServerEvent {
  const ServerDatabaseUpdated({required this.lastUpdated});

  final DateTime lastUpdated;
}
