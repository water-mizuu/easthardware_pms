part of 'user_log_report_bloc.dart';

abstract class UserLogReportEvent extends Equatable {
  const UserLogReportEvent();

  @override
  List<Object?> get props => [];
}

class UserLogReportInitializeEvent extends UserLogReportEvent {
  const UserLogReportInitializeEvent();
}

class UserLogReportSetGeneratingEvent extends UserLogReportEvent {
  const UserLogReportSetGeneratingEvent(this.isGenerating);

  final bool isGenerating;

  @override
  List<Object?> get props => [isGenerating];
}

class UserLogReportSetStartDateEvent extends UserLogReportEvent {
  const UserLogReportSetStartDateEvent(this.startDate);

  final DateTime startDate;

  @override
  List<Object?> get props => [startDate];
}

class UserLogReportSetEndDateEvent extends UserLogReportEvent {
  const UserLogReportSetEndDateEvent(this.endDate);

  final DateTime endDate;

  @override
  List<Object?> get props => [endDate];
}

class UserLogReportSetSortByEvent extends UserLogReportEvent {
  const UserLogReportSetSortByEvent(this.sortBy);

  final UserLogsReportSortBy sortBy;

  @override
  List<Object?> get props => [sortBy];
}

class UserLogReportSetUserIdEvent extends UserLogReportEvent {
  const UserLogReportSetUserIdEvent(this.userId);

  final int? userId;

  @override
  List<Object?> get props => [userId];
}

class UserLogReportSetAccessLevelEvent extends UserLogReportEvent {
  const UserLogReportSetAccessLevelEvent(this.accessLevel);

  final AccessLevel? accessLevel;

  @override
  List<Object?> get props => [accessLevel];
}

class UserLogReportUpdateUserLogsEvent extends UserLogReportEvent {
  const UserLogReportUpdateUserLogsEvent(this.userLogs);

  final List<UserLog> userLogs;

  @override
  List<Object?> get props => [userLogs];
}

class UserLogReportUpdateUsersEvent extends UserLogReportEvent {
  const UserLogReportUpdateUsersEvent(this.users);

  final List<User> users;

  @override
  List<Object?> get props => [users];
}
