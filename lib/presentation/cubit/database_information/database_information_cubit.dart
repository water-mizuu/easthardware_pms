import 'package:easthardware_pms/data/database/dao/metadata_dao.dart';
import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;

part 'database_information_state.dart';

class DatabaseInformationCubit extends Cubit<DatabaseInformationState> {
  DatabaseInformationCubit(
    this._webSocketCustomChannel,
    this._metadataDao,
    super.initialState,
  );

  final WebSocketCustomChannel? _webSocketCustomChannel;
  WebSocketCustomChannel get _channel => _webSocketCustomChannel!;
  final MetadataDao _metadataDao;

  Future<void> loadMetadata() async {
    final recordCount = await _metadataDao.getRecordCount();
    final (latestBackupDateTime, backupPaths) = await _loadBackups();
    final databaseSize = await getDatabaseSize();

    emit(
      state.copyWith(
        recordCount: recordCount,
        allBackupPaths: backupPaths,
        latestBackupDateTime: latestBackupDateTime,
        databaseSize: databaseSize,
      ),
    );
    if (kDebugMode) {
      print(("Emitted new state: $state"));
    }
  }

  Future<void> createBackup({required String key}) async {
    try {
      await _channel.invoke("create_backup", [key]);
    } catch (e) {
      showNotification.error(title: 'Backup Failed', message: e.toString());
    }
  }

  Future<bool> restoreBackup({required String path, required String key}) async {
    try {
      await _channel.invoke("restore_backup", [path, key]);

      return true;
    } catch (e) {
      showNotification.error(title: 'Restore Failed', message: e.toString());

      return false;
    }
  }

  Future<void> deleteBackup({required String path}) async {
    try {
      await _channel.invoke("delete_backup", [path]);
    } catch (e) {
      showNotification.error(title: 'Delete Failed', message: e.toString());
    }
  }

  Future<int> getDatabaseSize() async {
    try {
      final size = await _channel.invoke("get_database_size");

      return size;
    } catch (e) {
      showNotification.error(title: 'Get Database Size Failed', message: e.toString());
      return 0;
    }
  }

  Future<(DateTime?, List<String>)> _loadBackups() async {
    final potentialBackupPaths = await _channel //
        .invoke("load_backups")
        .then((v) => (v as List<dynamic>).cast<String>());

    final backupPaths = <String>[];
    for (final backupPath in potentialBackupPaths) {
      if (backupPath.isEmpty) continue;

      final split = backupPath.split("_");
      if (split.length < 2) continue;

      final baseName = path.basenameWithoutExtension(split.last);
      final dateCreated = int.tryParse(baseName);
      if (dateCreated == null) continue;

      backupPaths.add(backupPath);
    }

    final latestDateTime = backupPaths.isEmpty
        ? null
        : backupPaths
            .map((p) => p.split("_").last)
            .map(path.basenameWithoutExtension)
            .map(int.parse)
            .map(DateTime.fromMillisecondsSinceEpoch)
            .reduce((a, b) => a.isAfter(b) ? a : b);

    /// Make a shallow copy to make it mutable.

    return (latestDateTime, backupPaths);
  }
}
