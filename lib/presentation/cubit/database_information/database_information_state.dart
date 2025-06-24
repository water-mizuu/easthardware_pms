part of 'database_information_cubit.dart';

final class DatabaseInformationState with EquatableMixin {
  const DatabaseInformationState({this.recordCount = 0});

  final int recordCount;

  DatabaseInformationState Function({
    int recordCount,
  }) get copyWith {
    return ({
      Object? recordCount = undefined,
    }) {
      return DatabaseInformationState(
        recordCount: recordCount.or(this.recordCount),
      );
    };
  }

  @override
  List<Object?> get props => [recordCount];
}
