part of 'user_log_list_bloc.dart';

class UserLogListState extends Equatable {
  const UserLogListState({
    this.userLogs = const [],
    this.filteredLogs = const [],
    this.query,
    this.accessLevelQuery,
    this.status = DataStatus.initial,
    this.errorMessage,
  });

  final List<UserLog> userLogs;
  final List<UserLog> filteredLogs;
  final String? query;
  final AccessLevel? accessLevelQuery;
  final DataStatus status;
  final String? errorMessage;

  @override
  List<Object?> get props =>
      [userLogs, filteredLogs, query, accessLevelQuery, status, errorMessage];

  UserLogListState Function({
    List<UserLog> userLogs,
    List<UserLog> filteredLogs,
    String? query,
    AccessLevel? accessLevelQuery,
    DataStatus status,
    String? errorMessage,
  }) get copyWith {
    return ({
      Object? userLogs = undefined,
      Object? filteredLogs = undefined,
      Object? query = undefined,
      Object? accessLevelQuery = undefined,
      Object? status = undefined,
      Object? errorMessage = undefined,
    }) {
      return UserLogListState(
        userLogs: userLogs.or(this.userLogs),
        filteredLogs: filteredLogs.or(this.filteredLogs),
        query: query.or(this.query),
        accessLevelQuery: accessLevelQuery.or(this.accessLevelQuery),
        status: status.or(this.status),
        errorMessage: errorMessage.or(this.errorMessage),
      );
    };
  }
}
