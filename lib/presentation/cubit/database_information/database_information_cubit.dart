import 'package:easthardware_pms/data/database/dao/metadata_dao.dart';
import 'package:easthardware_pms/data/database/database_server_proxy.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'database_information_state.dart';

class DatabaseInformationCubit extends Cubit<DatabaseInformationState> {
  DatabaseInformationCubit(this._channel, this._metadataDao, super.initialState);

  final WebSocketCustomChannel? _channel;
  final MetadataDao _metadataDao;

  Future<void> loadMetadata() async {
    emit(
      state.copyWith(
        recordCount: await _metadataDao.getRecordCount(),
        allBackupPaths: await _channel!.invoke("load_backups"),
      ),
    );
  }

  Future<void> createBackup({required String key}) async {
    try {
      await _channel!.invoke("create_backup", [key]);
    } catch (e) {
      showNotification.error(title: 'Backup Failed', message: e.toString());
    }
  }

  Future<void> restoreBackup({required String path, required String key}) async {
    try {
      await _channel!.invoke("restore_backup", [path, key]);
    } catch (e) {
      showNotification.error(title: 'Restore Failed', message: e.toString());
    }
  }
}
