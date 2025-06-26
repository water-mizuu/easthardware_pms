part of 'database_information_cubit.dart';

final class DatabaseInformationState {
  const DatabaseInformationState({
    this.allRecords = const [],
    this.allBackupPaths = const [],
    this.latestBackupDateTime,
    this.databaseSize = 0,
    this.recordCount = 0,
  });

  final List<(String, List<Map<String, dynamic>>)> allRecords;
  final List<String> allBackupPaths;
  final DateTime? latestBackupDateTime;
  final int databaseSize;
  final int recordCount;

  DatabaseInformationState Function({
    List<(String, List<Map<String, dynamic>>)> allRecords,
    List<String> allBackupPaths,
    DateTime? latestBackupDateTime,
    int databaseSize,
    int recordCount,
  }) get copyWith {
    return ({
      Object? allRecords = undefined,
      Object? allBackupPaths = undefined,
      Object? latestBackupDateTime = undefined,
      Object? databaseSize = undefined,
      Object? recordCount = undefined,
    }) {
      return DatabaseInformationState(
        allRecords: allRecords.or(this.allRecords),
        allBackupPaths: allBackupPaths.or(this.allBackupPaths),
        latestBackupDateTime: latestBackupDateTime.or(this.latestBackupDateTime),
        databaseSize: databaseSize.or(this.databaseSize),
        recordCount: recordCount.or(this.recordCount),
      );
    };
  }
}
