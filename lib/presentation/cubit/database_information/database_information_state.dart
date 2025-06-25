part of 'database_information_cubit.dart';

final class DatabaseInformationState with EquatableMixin {
  const DatabaseInformationState({
    this.allRecords = const [],
    this.recordCount = 0,
  });

  final List<(String, List<Map<String, dynamic>>)> allRecords;
  final int recordCount;

  DatabaseInformationState Function({
    List<(String, List<Map<String, dynamic>>)> allRecords,
    int recordCount,
  }) get copyWith {
    return ({
      Object? allRecords = undefined,
      Object? recordCount = undefined,
    }) {
      return DatabaseInformationState(
        allRecords: allRecords.or(this.allRecords),
        recordCount: recordCount.or(this.recordCount),
      );
    };
  }

  @override
  List<Object?> get props => [allRecords, recordCount];
}
