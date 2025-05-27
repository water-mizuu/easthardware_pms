import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/models/user_log.dart';
import 'package:easthardware_pms/domain/repository/user_log_repository.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'user_log_list_event.dart';
part 'user_log_list_state.dart';

class UserLogListBloc extends Bloc<UserLogListEvent, UserLogListState> {
  final UserLogRepository _repository;

  UserLogListBloc(this._repository) : super(const UserLogListState()) {
    on<LoadUserLogsEvent>(_onLoadUserLogs);
    on<AddCreateEvent>(_onAddCreateLog);
    on<AddUpdateEvent>(_onAddUpdateLog);
    on<AddArchiveEvent>(_onAddArchiveLog);
    on<UpdateUserLogEvent>(_onUpdateUserLog);
    on<DeleteUserLogEvent>(_onDeleteUserLog);
    on<AddLoginEvent>(_onAddLoginLog);
    on<AddLogoutEvent>(_onAddLogoutLog);
    on<FilterUserLogsEvent>(_onFilterUserLogs);
  }

  void _onLoadUserLogs(LoadUserLogsEvent event, Emitter<UserLogListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final userLogs = await _repository.getAllUserLogs();
      emit(state.copyWith(status: DataStatus.success, userLogs: userLogs));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error loading user logs: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  void _onAddCreateLog(AddCreateEvent event, Emitter<UserLogListState> emit) async {
    try {
      final String logEvent = "Created ${event.item}";
      final DateTime logDateTime = DateTime.now();
      final UserLog userLog = UserLog(
        userId: event.user.id!,
        event: logEvent,
        eventTime: logDateTime,
      );
      final insertedUserLog = await _repository.insertUserLog(userLog);
      final userLogs = List<UserLog>.from(state.userLogs)..add(insertedUserLog);

      emit(state.copyWith(userLogs: userLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error inserting user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  void _onAddUpdateLog(AddUpdateEvent event, Emitter<UserLogListState> emit) async {
    try {
      final String logEvent = "Updated ${event.item}";
      final DateTime logDateTime = DateTime.now();
      final UserLog userLog = UserLog(
        userId: event.user.id!,
        event: logEvent,
        eventTime: logDateTime,
      );
      final insertedUserLog = await _repository.insertUserLog(userLog);
      final userLogs = List<UserLog>.from(state.userLogs)..add(insertedUserLog);

      emit(state.copyWith(userLogs: userLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error inserting user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  void _onAddArchiveLog(AddArchiveEvent event, Emitter<UserLogListState> emit) async {
    try {
      final String logEvent = "Archived ${event.item}";
      final DateTime logDateTime = DateTime.now();
      final UserLog userLog = UserLog(
        userId: event.user.id!,
        event: logEvent,
        eventTime: logDateTime,
      );
      final insertedUserLog = await _repository.insertUserLog(userLog);
      final userLogs = List<UserLog>.from(state.userLogs)..add(insertedUserLog);

      emit(state.copyWith(userLogs: userLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error inserting user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  void _onAddLoginLog(AddLoginEvent event, Emitter emit) async {
    try {
      final String logEvent = "${event.user.firstName} ${event.user.lastName} Logged in";
      final DateTime logDateTime = DateTime.now();
      final UserLog userLog = UserLog(
        userId: event.user.id!,
        event: logEvent,
        eventTime: logDateTime,
      );
      final insertedUserLog = await _repository.insertUserLog(userLog);
      final userLogs = List<UserLog>.from(state.userLogs)..add(insertedUserLog);

      emit(state.copyWith(userLogs: userLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error inserting user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  void _onUpdateUserLog(UpdateUserLogEvent event, Emitter<UserLogListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final updatedUserLog = await _repository.updateUserLog(event.userLog);
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
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  void _onDeleteUserLog(DeleteUserLogEvent event, Emitter<UserLogListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _repository.deleteUserLog(event.userLog);
      final updatedUserLogs = List<UserLog>.from(state.userLogs)
          .where((userLog) => userLog.id != event.userLog.id)
          .toList();
      emit(state.copyWith(userLogs: updatedUserLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error deleting user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  void _onFilterUserLogs(FilterUserLogsEvent event, Emitter<UserLogListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final filteredUserLogs = await _repository.getUserLogByUserId(event.id);
      emit(state.copyWith(filteredLogs: filteredUserLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error filtering user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  void _onAddLogoutLog(AddLogoutEvent event, Emitter emit) async {
    try {
      final String logEvent = "${event.user.firstName} ${event.user.lastName} Logged out";
      final DateTime logDateTime = DateTime.now();
      final UserLog userLog = UserLog(
        userId: event.user.id!,
        event: logEvent,
        eventTime: logDateTime,
      );
      final insertedUserLog = await _repository.insertUserLog(userLog);
      final userLogs = List<UserLog>.from(state.userLogs)..add(insertedUserLog);

      emit(state.copyWith(userLogs: userLogs, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error inserting user log: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }
}
