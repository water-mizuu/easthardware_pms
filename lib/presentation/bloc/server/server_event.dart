part of 'server_bloc.dart';

sealed class ServerEvent {
  const ServerEvent();
}

class ServerReset implements ServerEvent {
  const ServerReset();
}

class ServerInit implements ServerEvent {
  const ServerInit();
}

class _ServerPromptingUserFromNull implements ServerEvent {
  const _ServerPromptingUserFromNull();
}

class _ServerLoadingClientFromPreferences implements ServerEvent {
  const _ServerLoadingClientFromPreferences({
    required this.address,
    required this.popupToUser,
    required this.saveToPreferences,
  });

  final String address;
  final bool popupToUser;
  final bool saveToPreferences;
}

class _ServerPromptingClientInformation implements ServerEvent {
  const _ServerPromptingClientInformation();
}

class _ServerClientConnectionEstablished implements ServerEvent {
  const _ServerClientConnectionEstablished({
    required this.args,
    required this.popupToUser,
    required this.saveToPreferences,
  });

  final ClientDatabaseArgs args;
  final bool popupToUser;
  final bool saveToPreferences;
}

class _ServerLoadingServerFromPreferences implements ServerEvent {
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

class _ServerPromptingServerInformation implements ServerEvent {
  const _ServerPromptingServerInformation();
}

class _ServerServerStarted implements ServerEvent {
  const _ServerServerStarted({
    required this.args,
    required this.popupToUser,
    required this.saveToPreferences,
  });

  final ServerDatabaseArgs args;
  final bool popupToUser;
  final bool saveToPreferences;
}

class _ServerSaveClientInformation implements ServerEvent {
  const _ServerSaveClientInformation({required this.serverAddress});

  final String serverAddress;
}

class _ServerSaveServerInformation implements ServerEvent {
  const _ServerSaveServerInformation({required this.port});

  final int port;
}

class ServerDatabaseUpdated implements ServerEvent {
  const ServerDatabaseUpdated({required this.lastUpdated});

  final DateTime lastUpdated;
}

class ServerNotificationsReceived implements ServerEvent {
  const ServerNotificationsReceived({required this.notifications});

  final List<ServerNotification> notifications;
}

class _ServerResetBottomText implements ServerEvent {
  const _ServerResetBottomText();
}

class ServerDatabaseCleared implements ServerEvent {
  const ServerDatabaseCleared();
}

class ServerMockDataAdded implements ServerEvent {
  const ServerMockDataAdded();
}

/// Event triggered when the connection is lost
class _ServerConnectionLost implements ServerEvent {
  const _ServerConnectionLost();
}

/// Event to attempt reconnection
class _ServerAttemptReconnection implements ServerEvent {
  const _ServerAttemptReconnection();
}

/// Event to cancel reconnection attempts
class ServerCancelReconnection implements ServerEvent {
  const ServerCancelReconnection();
}

/// Event triggered when reconnection succeeds
class _ServerReconnectionSucceeded implements ServerEvent {
  const _ServerReconnectionSucceeded();
}

/// Event triggered when reconnection fails
class _ServerReconnectionFailed implements ServerEvent {
  const _ServerReconnectionFailed();
}
