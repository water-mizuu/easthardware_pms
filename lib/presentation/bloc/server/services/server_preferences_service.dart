import 'package:easthardware_pms/backend/enum/database_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class that handles shared preferences for server configuration
/// Resets the shared preferences by removing the server address, port, and mode.
/// Returns the instance of SharedPreferencesAsync.
Future<SharedPreferencesAsync> resetSharedPreferences() async {
  final sharedPreferences = SharedPreferencesAsync();
  await sharedPreferences.remove("serverAddress");
  await sharedPreferences.remove("port");
  await sharedPreferences.remove("mode");

  return sharedPreferences;
}

/// Gets the saved database mode
Future<DatabaseMode?> getSavedDatabaseMode() async {
  final sharedPreferences = SharedPreferencesAsync();
  final mode = await sharedPreferences.getInt("mode");
  return mode == null ? null : DatabaseMode.values[mode];
}

/// Gets the saved server address
Future<String?> getSavedServerAddress() async {
  final sharedPreferences = SharedPreferencesAsync();
  return await sharedPreferences.getString("serverAddress");
}

/// Gets the saved server port
Future<int?> getSavedServerPort() async {
  final sharedPreferences = SharedPreferencesAsync();
  return await sharedPreferences.getInt("port");
}

/// Saves client information to shared preferences
Future<void> saveClientInformation(String serverAddress) async {
  if (kDebugMode) {
    print("Saving client information: $serverAddress");
  }

  final sharedPreferences = await resetSharedPreferences();
  await sharedPreferences.setString("serverAddress", serverAddress);
  await sharedPreferences.setInt("mode", DatabaseMode.client.index);
}

/// Saves server information to shared preferences
Future<void> saveServerInformation(int port) async {
  if (kDebugMode) {
    print("Saving server information: $port");
  }

  final sharedPreferences = await resetSharedPreferences();
  await sharedPreferences.setInt("port", port);
  await sharedPreferences.setInt("mode", DatabaseMode.server.index);
}
