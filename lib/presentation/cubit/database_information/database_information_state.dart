part of 'database_information_cubit.dart';

final class DatabaseInformationState with EquatableMixin {
  const DatabaseInformationState({
    this.allRecords = const [],
    this.allBackupPaths = const [],
    this.recordCount = 0,
  });

  final List<(String, List<Map<String, dynamic>>)> allRecords;
  final List<String> allBackupPaths;
  final int recordCount;

  DatabaseInformationState Function({
    List<(String, List<Map<String, dynamic>>)> allRecords,
    List<String> allBackupPaths,
    int recordCount,
  }) get copyWith {
    return ({
      Object? allRecords = undefined,
      Object? allBackupPaths = undefined,
      Object? recordCount = undefined,
    }) {
      return DatabaseInformationState(
        allRecords: allRecords.or(this.allRecords),
        allBackupPaths: allBackupPaths.or(this.allBackupPaths),
        recordCount: recordCount.or(this.recordCount),
      );
    };
  }

  @override
  List<Object?> get props => [allRecords, allBackupPaths, recordCount];
}
