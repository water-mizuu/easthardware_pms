part of 'user_log_list_bloc.dart';

class UserLogListState extends Equatable {
  UserLogListState({
    this.userLogs = const [],
    this.filteredLogs = const [],
    UserLogQueryData? queryData,
    this.status = DataStatus.initial,
    this.errorMessage,
  }) : queryData = queryData ?? UserLogQueryData();

  final List<UserLog> userLogs;
  final List<UserLog> filteredLogs;
  final UserLogQueryData queryData;
  final DataStatus status;
  final String? errorMessage;

  @override
  List<Object?> get props => [userLogs, filteredLogs, queryData, status, errorMessage];

  UserLogListState Function({
    List<UserLog> userLogs,
    List<UserLog> filteredLogs,
    UserLogQueryData? queryData,
    DataStatus status,
    String? errorMessage,
  }) get copyWith {
    return ({
      Object? userLogs = undefined,
      Object? filteredLogs = undefined,
      Object? queryData = undefined,
      Object? status = undefined,
      Object? errorMessage = undefined,
    }) {
      return UserLogListState(
        userLogs: userLogs.or(this.userLogs),
        filteredLogs: filteredLogs.or(this.filteredLogs),
        queryData: queryData.or(this.queryData),
        status: status.or(this.status),
        errorMessage: errorMessage.or(this.errorMessage),
      );
    };
  }
}

final class UserLogQueryData with EquatableMixin {
  UserLogQueryData({
    this.query,
    this.accessLevel,
    DateTime? startDate,
    DateTime? endDate,
  })  : startDate = startDate ?? DateTime(DateTime.now().year).zeroedTime(),
        endDate = endDate ?? DateTime.now().zeroedTime();

  final String? query;
  final AccessLevel? accessLevel;
  final DateTime startDate;
  final DateTime endDate;

  UserLogQueryData Function({
    String? query,
    AccessLevel? accessLevel,
    DateTime? startDate,
    DateTime? endDate,
  }) get copyWith {
    return ({
      Object? query = undefined,
      Object? accessLevel = undefined,
      Object? startDate = undefined,
      Object? endDate = undefined,
    }) {
      return UserLogQueryData(
        query: query.or(this.query),
        accessLevel: accessLevel.or(this.accessLevel),
        startDate: startDate.or(this.startDate),
        endDate: endDate.or(this.endDate),
      );
    };
  }

  @override
  List<Object?> get props => [query, accessLevel, startDate, endDate];
}
