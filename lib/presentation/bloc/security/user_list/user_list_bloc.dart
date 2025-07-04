import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:dart_bloc_concurrency/dart_bloc_concurrency.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/domain/repository/user_repository.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/duration.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:easthardware_pms/domain/constants/debug_constants.dart';
import 'package:equatable/equatable.dart';


part 'user_list_event.dart';
part 'user_list_state.dart';

const _levenshteinThreshold = 20.0;

class UserListBloc extends Bloc<UserListEvent, UserListState> {
  UserListBloc(this._repository, UserListState initialState) : super(initialState) {
    on<LoadAllUsersEvent>(_onLoadUsers);
    on<AddUserEvent>(_onAddUser);
    on<UpdateUserEvent>(_onUpdateUser);
    on<ArchiveUserEvent>(_onArchiveUser);
    on<UnarchiveUserEvent>(_onUnarchiveUser);
    on<DeleteUserEvent>(_onDeleteUser);
    on<UserLoggedInEvent>(_onUserLoggedIn);
    on<UserLoggedOutEvent>(_onUserLoggedOut);

    on<FilterUsersByAccessLevelEvent>(_onFilterByAccessLevel);
    on<SearchUsersByStringEvent>(_onSearchByString, transformer: debounce(200.ms));
  }
  final UserRepository _repository;

  @override
  void onEvent(UserListEvent event) {
    super.onEvent(event);

    if (isDebugMode) {
      printBoxed('UserListBloc: Received event: $event');
    }
  }

  Future<void> _onLoadUsers(LoadAllUsersEvent event, Emitter<UserListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final users = await _repository.getAllUsers();

      emit(state.copyWith(
        status: DataStatus.success,
        users: users,
        filteredUsers: users,
      ));
    } catch (e) {
      if (isDebugMode) {
        printBoxed('Error loading users $e');
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAddUser(AddUserEvent event, Emitter<UserListState> emit) async {
    assert(event.user.id != null, "For debugging purposes, user ID should not be null.");
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final insertedUser = await _repository.insertUser(event.user);
      assert(
        event.user.id == insertedUser.id,
        "User ID should match after insertion. "
        "If not, this is a bug in the application assumptions.",
      );

      final users = List<User>.from(state.users)..add(insertedUser);
      emit(state.copyWith(users: users, filteredUsers: users, status: DataStatus.success));
    } catch (e) {
      if (isDebugMode) {
        printBoxed('Error adding user $e');
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onUpdateUser(UpdateUserEvent event, Emitter<UserListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final updatedUser = await _repository.updateUser(event.user);

      final updatedUsers = List<User>.from(state.users);
      final index = updatedUsers.indexWhere((user) => user.id == updatedUser.id);
      if (index != -1) {
        updatedUsers[index] = updatedUser;
      }

      emit(state.copyWith(
        users: updatedUsers,
        filteredUsers: updatedUsers,
        status: DataStatus.success,
      ));
    } catch (e) {
      if (isDebugMode) {
        printBoxed('Error updating user $e');
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onArchiveUser(ArchiveUserEvent event, Emitter<UserListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final updatedUser = event.user.copyWith(archiveStatus: 1);
      await _repository.updateUser(updatedUser);
      final updatedUsers = List<User>.from(state.users);
      final index = updatedUsers.indexWhere((user) => user.id == updatedUser.id);
      if (index != -1) {
        updatedUsers[index] = updatedUser;
      }

      emit(
        state.copyWith(
          users: updatedUsers,
          filteredUsers: updatedUsers,
          status: DataStatus.success,
        ),
      );
    } catch (e) {
      if (isDebugMode) {
        printBoxed('Error archiving user $e');
      }
    }
  }

  Future<void> _onUnarchiveUser(UnarchiveUserEvent event, Emitter<UserListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final updatedUser = event.user.copyWith(archiveStatus: 0);
      await _repository.updateUser(updatedUser);
      final updatedUsers = List<User>.from(state.users);
      final index = updatedUsers.indexWhere((user) => user.id == updatedUser.id);
      if (index != -1) {
        updatedUsers[index] = updatedUser;
      }

      emit(
        state.copyWith(
          users: updatedUsers,
          filteredUsers: updatedUsers,
          status: DataStatus.success,
        ),
      );
    } catch (e) {
      if (isDebugMode) {
        printBoxed('Error archiving user $e');
      }
    }
  }

  Future<void> _onDeleteUser(DeleteUserEvent event, Emitter<UserListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _repository.deleteUser(event.user);
      final updatedUsers = state.users //
          .where((user) => user.id != event.user.id)
          .toList();

      emit(state.copyWith(
        users: updatedUsers,
        filteredUsers: updatedUsers,
        status: DataStatus.success,
      ));
    } catch (e) {
      if (isDebugMode) {
        printBoxed('Error deleting user $e');
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onUserLoggedIn(UserLoggedInEvent event, Emitter<UserListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    await _repository.setUserAsActive(event.userId);
    final user = state.users.firstWhere((user) => user.id == event.userId);
    final updatedUsers = List<User>.from(state.users);
    final index = updatedUsers.indexWhere((u) => u.id == user.id);
    updatedUsers[index] = user.copyWith(loginStatus: 1);

    if (isDebugMode) {
      printBoxed('UserListBloc: User logged in: ${user.username} (ID: ${user.id})');
    }

    emit(state.copyWith(
      users: updatedUsers,
      filteredUsers: updatedUsers,
      status: DataStatus.success,
    ));
  }

  Future<void> _onUserLoggedOut(UserLoggedOutEvent event, Emitter<UserListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _repository.setUserAsInactive(event.userId);
      final user = state.users.firstWhere((user) => user.id == event.userId);
      final updatedUsers = List<User>.from(state.users);
      final index = updatedUsers.indexWhere((u) => u.id == user.id);
      updatedUsers[index] = user.copyWith(loginStatus: 0);

      if (isDebugMode) {
        printBoxed('UserListBloc: User logged out: ${user.username} (ID: ${user.id})');
      }

      emit(state.copyWith(
        users: updatedUsers,
        filteredUsers: updatedUsers,
        status: DataStatus.success,
      ));
    } catch (e, st) {
      if (isDebugMode) {
        printBoxed('Error logging out user $e\n$st');
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onFilterByAccessLevel(
    FilterUsersByAccessLevelEvent event,
    Emitter<UserListState> emit,
  ) async {
    final shown = _filterUsers(
      state.users,
      state.searchQuery,
      event.accessLevelQuery,
    );

    emit(state.copyWith(
      accessLevelQuery: event.accessLevelQuery,
      filteredUsers: shown,
    ));
  }

  Future<void> _onSearchByString(
    SearchUsersByStringEvent event,
    Emitter<UserListState> emit,
  ) async {
    final shown = _filterUsers(
      state.users,
      event.searchQuery,
      state.accessLevelQuery,
    );

    emit(state.copyWith(
      searchQuery: event.searchQuery,
      filteredUsers: shown,
    ));
  }

  static List<User> _filterUsers(
    List<User> allUsers,
    String? searchQuery,
    AccessLevel? accessLevelQuery,
  ) {
    var filteredUsers = allUsers
        .where((u) => accessLevelQuery == null || u.accessLevel == accessLevelQuery)
        .toList();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final matchedValues = {
        for (final user in filteredUsers) //
          user: [
            user.username.toLowerCase(),
            user.firstName.toLowerCase(),
            user.lastName.toLowerCase(),
          ]
      };

      final query = searchQuery.toLowerCase();
      final scores = matchedValues.map(
        (key, values) => MapEntry(
          key,
          values.map((v) => Levenshtein.distance(query, v, _levenshteinThreshold)).reduce(min),
        ),
      );
      final lowest = scores.values.fold(_levenshteinThreshold + 1, min);

      /// We only show the ones with the score which is 20% above the lowest score.
      final shown = scores.entries //
          .where((e) => e.value <= lowest * 1.2)
          .map((e) => e.key)
          .toList()
        ..sort((a, b) => scores[a]!.compareTo(scores[b]!));

      filteredUsers = shown;
    }

    return filteredUsers;
  }
}
