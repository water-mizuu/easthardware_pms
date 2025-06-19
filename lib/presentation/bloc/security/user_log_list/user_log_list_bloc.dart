import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dart_bloc_concurrency/dart_bloc_concurrency.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/models/user_log.dart';
import 'package:easthardware_pms/domain/repository/user_log_repository.dart';
import 'package:easthardware_pms/domain/repository/user_repository.dart';
import 'package:easthardware_pms/utils/duration.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:easthardware_pms/utils/zip.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';

part 'user_log_list_event.dart';
part 'user_log_list_state.dart';

class UserLogListBloc extends Bloc<UserLogListEvent, UserLogListState> {
  UserLogListBloc(
    this._userRepository,
    this._userLogRepository,
    UserLogListState initialState,
  ) : super(initialState) {
    on<LoadUserLogsEvent>(_onLoadUserLogs);
    on<AddCreateEvent>(_onAddCreateLog);
    on<AddUpdateEvent>(_onAddUpdateLog);
    on<AddArchiveEvent>(_onAddArchiveLog);
    on<UpdateUserLogEvent>(_onUpdateUserLog);
    on<DeleteUserLogEvent>(_onDeleteUserLog);
    on<AddLoginEvent>(_onAddLoginLog);
    on<AddLogoutEvent>(_onAddLogoutLog);

    on<SearchQueryUpdatedEvent>(_onSearchQueryUpdated, transformer: debounce(1.seconds));
    on<AccessLevelQueryUpdatedEvent>(_onAccessLevelQueryUpdated);
    on<_FilterUserLogsEvent>(_onFilterUserLogs);
  }
  final UserRepository _userRepository;
  final UserLogRepository _userLogRepository;

  Future<void> _onLoadUserLogs(LoadUserLogsEvent event, Emitter<UserLogListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final userLogs = await _userLogRepository.getAllUserLogs();
      emit(state.copyWith(status: DataStatus.success, userLogs: userLogs, filteredLogs: userLogs));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error loading user logs: $e");
      }
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddCreateLog(AddCreateEvent event, Emitter<UserLogListState> emit) async {
    try {
      final userLog = UserLog.create(user: event.user, item: event.item);
      final insertedUserLog = await _userLogRepository.insertUserLog(userLog);
      final userLogs = List<UserLog>.from(state.userLogs)..add(insertedUserLog);

      emit(state.copyWith(userLogs: userLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error inserting user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddUpdateLog(AddUpdateEvent event, Emitter<UserLogListState> emit) async {
    try {
      final userLog = UserLog.update(user: event.user, item: event.item);
      final insertedUserLog = await _userLogRepository.insertUserLog(userLog);
      final userLogs = List<UserLog>.from(state.userLogs)..add(insertedUserLog);

      emit(state.copyWith(userLogs: userLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error inserting user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddArchiveLog(AddArchiveEvent event, Emitter<UserLogListState> emit) async {
    try {
      final userLog = UserLog.archive(user: event.user, item: event.item);
      final insertedUserLog = await _userLogRepository.insertUserLog(userLog);
      final userLogs = List<UserLog>.from(state.userLogs)..add(insertedUserLog);

      emit(state.copyWith(userLogs: userLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error inserting user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddLoginLog(AddLoginEvent event, Emitter<UserLogListState> emit) async {
    try {
      final userLog = UserLog.login(user: event.user);
      final insertedUserLog = await _userLogRepository.insertUserLog(userLog);
      final userLogs = List<UserLog>.from(state.userLogs)..add(insertedUserLog);

      emit(state.copyWith(userLogs: userLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error inserting user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateUserLog(UpdateUserLogEvent event, Emitter<UserLogListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final updatedUserLog = await _userLogRepository.updateUserLog(event.userLog);
      final updatedUserLogs = List<UserLog>.from(state.userLogs);

      final index = updatedUserLogs.indexWhere((userLog) => userLog.id == updatedUserLog.id);
      if (index != -1) {
        updatedUserLogs[index] = updatedUserLog;
      }

      emit(state.copyWith(userLogs: updatedUserLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error updating user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteUserLog(DeleteUserLogEvent event, Emitter<UserLogListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _userLogRepository.deleteUserLog(event.userLog);
      final updatedUserLogs = List<UserLog>.from(state.userLogs)
          .where((userLog) => userLog.id != event.userLog.id)
          .toList();
      emit(state.copyWith(userLogs: updatedUserLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error deleting user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onFilterUserLogs(_FilterUserLogsEvent event, Emitter<UserLogListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final query = state.query;
      final assignedUsers = await state.userLogs //
          .map((log) => _userRepository.getUserById(log.userId))
          .toList()
          .wait;

      final usersForEachLog = {
        for (final (user, log) in assignedUsers.zip(state.userLogs)) log.id: user
      };

      final selectedUserLogs = state.userLogs //
          .where((log) =>
              state.accessLevelQuery == null ||
              state.accessLevelQuery == usersForEachLog[log.id]?.accessLevel)
          .toList();

      final ranked = await Levenshtein.rankItems(
        selectedUserLogs,
        query ?? '',
        (log) => {
          log.id.toString(),
          log.event,
          if (usersForEachLog[log.id] case final user?) ...[
            user.firstName,
            user.lastName,
            user.accessLevel.toString(),
          ]
        },
        (a, b) => a.eventTime.difference(b.eventTime).inMilliseconds,
      );

      emit(state.copyWith(
        filteredLogs: ranked,
        status: DataStatus.success,
      ));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error filtering user log: $e");
      }
      showNotification(title: "Error", message: e.toString(), severity: InfoBarSeverity.error);
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAddLogoutLog(AddLogoutEvent event, Emitter<UserLogListState> emit) async {
    try {
      final userLog = UserLog.logout(user: event.user);
      final insertedUserLog = await _userLogRepository.insertUserLog(userLog);
      final userLogs = List<UserLog>.from(state.userLogs)..add(insertedUserLog);

      emit(state.copyWith(userLogs: userLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error inserting user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSearchQueryUpdated(
    SearchQueryUpdatedEvent event,
    Emitter<UserLogListState> emit,
  ) async {
    emit(state.copyWith(query: event.query));
    add(const _FilterUserLogsEvent());
  }

  Future<void> _onAccessLevelQueryUpdated(
    AccessLevelQueryUpdatedEvent event,
    Emitter<UserLogListState> emit,
  ) async {
    emit(state.copyWith(accessLevelQuery: event.accessLevel));
    add(const _FilterUserLogsEvent());
  }
}
