import 'package:easthardware_pms/data/database/dao/metadata_dao.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'database_information_state.dart';

class DatabaseInformationCubit extends Cubit<DatabaseInformationState> {
  DatabaseInformationCubit(this._metadataDao, super.initialState);

  final MetadataDao _metadataDao;

  Future<void> loadMetadata() async {
    emit(state.copyWith(recordCount: await _metadataDao.getRecordCount()));
  }
}
