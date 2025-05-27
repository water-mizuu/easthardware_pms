part of 'user_log_list_bloc.dart';

class UserLogListState extends Equatable {
  const UserLogListState({
    this.userLogs = const [],
    this.filteredLogs = const [],
    this.status = DataStatus.initial,
  });

  final List<UserLog> userLogs;
  final List<UserLog> filteredLogs;
  final DataStatus status;

  @override
  List<Object> get props => [userLogs, filteredLogs, status];

  UserLogListState Function({
    List<UserLog> userLogs,
    List<UserLog> filteredLogs,
    DataStatus status,
  }) get copyWith {
    return ({
      Object? userLogs = undefined,
      Object? filteredLogs = undefined,
      Object? status = undefined,
    }) {
      return UserLogListState(
        userLogs: userLogs.or(this.userLogs),
        filteredLogs: filteredLogs.or(this.filteredLogs),
        status: status.or(this.status),
      );
    };
  }
}
