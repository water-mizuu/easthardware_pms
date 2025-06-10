part of 'user_log_list_bloc.dart';

class UserLogListState extends Equatable {
  const UserLogListState({
    this.userLogs = const [],
    this.filteredLogs = const [],
    this.status = DataStatus.initial,
    this.errorMessage,
  });

  final List<UserLog> userLogs;
  final List<UserLog> filteredLogs;
  final DataStatus status;
  final String? errorMessage;

  @override
  List<Object?> get props => [userLogs, filteredLogs, status, errorMessage];

  UserLogListState Function({
    List<UserLog> userLogs,
    List<UserLog> filteredLogs,
    DataStatus status,
    String? errorMessage,
  }) get copyWith {
    return ({
      Object? userLogs = undefined,
      Object? filteredLogs = undefined,
      Object? status = undefined,
      Object? errorMessage = undefined,
    }) {
      return UserLogListState(
        userLogs: userLogs.or(this.userLogs),
        filteredLogs: filteredLogs.or(this.filteredLogs),
        status: status.or(this.status),
        errorMessage: errorMessage.or(this.errorMessage),
      );
    };
  }
}
