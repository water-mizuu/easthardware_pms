part of 'user_log_list_bloc.dart';

class UserLogListState extends Equatable {
  final List<UserLog> userlogs;
  final List<UserLog> filteredLogs;
  final DataStatus status;
  const UserLogListState({
    this.userlogs = const [],
    this.filteredLogs = const [],
    this.status = DataStatus.initial,
  });

  @override
  List<Object> get props => [userlogs, filteredLogs, status];

  UserLogListState Function({
    List<UserLog> userlogs,
    List<UserLog> filteredLogs,
    DataStatus status,
  }) get copyWith {
    return ({
      Object? userlogs = undefined,
      Object? filteredLogs = undefined,
      Object? status = undefined,
    }) {
      return UserLogListState(
        userlogs: userlogs.or(this.userlogs),
        filteredLogs: filteredLogs.or(this.filteredLogs),
        status: status.or(this.status),
      );
    };
  }
}
