part of 'user_log_report_bloc.dart';

class UserLogReportState extends Equatable {
  const UserLogReportState({
    required this.allUserLogs,
    required this.allUsers,
    required this.queryData,
    this.isGenerating = false,
  });

  final List<UserLog> allUserLogs;
  final List<User> allUsers;
  final UserLogsReportQueryData queryData;
  final bool isGenerating;

  UserLogReportState Function({
    List<UserLog>? allUserLogs,
    List<User>? allUsers,
    UserLogsReportQueryData? queryData,
    bool? isGenerating,
  }) get copyWith {
    return ({
      Object? allUserLogs = undefined,
      Object? allUsers = undefined,
      Object? queryData = undefined,
      Object? isGenerating = undefined,
    }) {
      return UserLogReportState(
        allUserLogs: allUserLogs.or(this.allUserLogs),
        allUsers: allUsers.or(this.allUsers),
        queryData: queryData.or(this.queryData),
        isGenerating: isGenerating.or(this.isGenerating),
      );
    };
  }

  @override
  List<Object?> get props => [allUserLogs, allUsers, queryData, isGenerating];
}
