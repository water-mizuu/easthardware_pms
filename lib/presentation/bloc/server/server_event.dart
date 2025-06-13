part of 'server_bloc.dart';

sealed class ServerEvent {
  const ServerEvent();
}

class ServerReset extends ServerEvent {
  const ServerReset();
}

class ServerInit extends ServerEvent {
  const ServerInit();
}

class _ServerPromptingUserFromNull extends ServerEvent {
  const _ServerPromptingUserFromNull();
}

class _ServerLoadingClientFromPreferences extends ServerEvent {
  const _ServerLoadingClientFromPreferences({
    required this.address,
    required this.popupToUser,
    required this.saveToPreferences,
  });

  final String address;
  final bool popupToUser;
  final bool saveToPreferences;
}

class _ServerPromptingClientInformation extends ServerEvent {
  const _ServerPromptingClientInformation();
}

class _ServerClientConnectionEstablished extends ServerEvent {
  const _ServerClientConnectionEstablished({
    required this.args,
    required this.popupToUser,
    required this.saveToPreferences,
  });

  final ClientDatabaseArgs args;
  final bool popupToUser;
  final bool saveToPreferences;
}

class _ServerLoadingServerFromPreferences extends ServerEvent {
  const _ServerLoadingServerFromPreferences({
    required this.port,
    // ignore: unused_element
    this.popupToUser = true,
    // ignore: unused_element
    this.saveToPreferences = false,
  });

  final int port;
  final bool popupToUser;
  final bool saveToPreferences;
}

class _ServerPromptingServerInformation extends ServerEvent {
  const _ServerPromptingServerInformation();
}

class _ServerServerStarted extends ServerEvent {
  const _ServerServerStarted({
    required this.args,
    required this.popupToUser,
    required this.saveToPreferences,
  });

  final ServerDatabaseArgs args;
  final bool popupToUser;
  final bool saveToPreferences;
}

class _ServerSaveClientInformation extends ServerEvent {
  const _ServerSaveClientInformation({required this.serverAddress});

  final String serverAddress;
}

class _ServerSaveServerInformation extends ServerEvent {
  const _ServerSaveServerInformation({required this.port});

  final int port;
}

class ServerDatabaseUpdated extends ServerEvent {
  const ServerDatabaseUpdated({required this.lastUpdated});

  final DateTime lastUpdated;
}

class _ServerResetBottomText extends ServerEvent {
  const _ServerResetBottomText();
}

class ServerDatabaseCleared extends ServerEvent {
  const ServerDatabaseCleared();
}

class ServerMockDataAdded extends ServerEvent {
  const ServerMockDataAdded();
}
