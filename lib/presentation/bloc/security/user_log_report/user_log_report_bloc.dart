import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/models/user_log.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/sales_overview.dart';
import 'package:easthardware_pms/presentation/views/reports/user_logs_report/user_logs_query_data.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

part 'user_log_report_event.dart';
part 'user_log_report_state.dart';

class UserLogReportBloc extends Bloc<UserLogReportEvent, UserLogReportState> {
  UserLogReportBloc(
    List<UserLog> allUserLogs,
    List<User> allUsers,
  ) : super(UserLogReportState(
          allUserLogs: allUserLogs,
          allUsers: allUsers,
          queryData: UserLogsReportQueryData.empty(),
        )) {
    on<UserLogReportInitializeEvent>(_onInitialize);
    on<UserLogReportSetGeneratingEvent>(_onSetGenerating);
    on<UserLogReportSetStartDateEvent>(_onSetStartDate);
    on<UserLogReportSetEndDateEvent>(_onSetEndDate);
    on<UserLogReportSetSortByEvent>(_onSetSortBy);
    on<UserLogReportSetUserIdEvent>(_onSetUserId);
    on<UserLogReportSetAccessLevelEvent>(_onSetAccessLevel);
    on<UserLogReportUpdateUserLogsEvent>(_onUpdateUserLogs);
    on<UserLogReportUpdateUsersEvent>(_onUpdateUsers);

    // Initialize the query data
    add(const UserLogReportInitializeEvent());
  }

  Future<void> _onInitialize(
    UserLogReportInitializeEvent event,
    Emitter<UserLogReportState> emit,
  ) async {
    _recalculateLogData(emit);
  }

  void _onSetGenerating(UserLogReportSetGeneratingEvent event, Emitter<UserLogReportState> emit) {
    emit(state.copyWith(isGenerating: event.isGenerating));
  }

  void _onSetStartDate(UserLogReportSetStartDateEvent event, Emitter<UserLogReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(startDate: event.startDate),
    ));
    _recalculateLogData(emit);
  }

  void _onSetEndDate(UserLogReportSetEndDateEvent event, Emitter<UserLogReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(endDate: event.endDate),
    ));
    _recalculateLogData(emit);
  }

  void _onSetSortBy(UserLogReportSetSortByEvent event, Emitter<UserLogReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(sortBy: event.sortBy),
    ));
    _recalculateLogData(emit);
  }

  void _onSetUserId(UserLogReportSetUserIdEvent event, Emitter<UserLogReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(
        selectedUserId: event.userId,
        selectedUserIdToNull: event.userId == null ? Object() : undefined,
      ),
    ));
    _recalculateLogData(emit);
  }

  void _onSetAccessLevel(UserLogReportSetAccessLevelEvent event, Emitter<UserLogReportState> emit) {
    emit(state.copyWith(
      queryData: state.queryData.copyWith(
        accessLevel: event.accessLevel,
        accessLevelToNull: event.accessLevel == null ? Object() : undefined,
      ),
    ));
    _recalculateLogData(emit);
  }

  void _onUpdateUserLogs(UserLogReportUpdateUserLogsEvent event, Emitter<UserLogReportState> emit) {
    emit(state.copyWith(allUserLogs: event.userLogs));
    _recalculateLogData(emit);
  }

  void _onUpdateUsers(UserLogReportUpdateUsersEvent event, Emitter<UserLogReportState> emit) {
    emit(state.copyWith(allUsers: event.users));
    _recalculateLogData(emit);
  }

  void _recalculateLogData(Emitter<UserLogReportState> emit) {
    final userLogs = state.allUserLogs;
    final users = state.allUsers;
    final startDate = state.queryData.startDate;
    final endDate = state.queryData.endDate;
    final sortBy = state.queryData.sortBy;
    final selectedUserId = state.queryData.selectedUserId;
    final accessLevel = state.queryData.accessLevel;

    // Create a map for quick user lookups
    final usersMap = {for (final user in users) user.id!: user};

    // Filter logs by date range
    final filteredLogs = userLogs
        .where((log) =>
            log.eventTime.isAfter(startDate.zeroedTime()) &&
            log.eventTime.isBefore(endDate.add(const Duration(days: 1))))

        // Filter by user if specified
        .where((log) => selectedUserId == null || log.userId == selectedUserId)

        // Filter by access level if specified
        .where((log) => switch (usersMap[log.userId]) {
              final user? when accessLevel == null || user.accessLevel == accessLevel => true,
              _ => false,
            })
        .toList()

      // Apply sorting
      ..sort((a, b) => sortBy.compare(a, b, usersMap));

    emit(state.copyWith(
      queryData: state.queryData.copyWith(filteredLogs: filteredLogs),
    ));
  }
}
