import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'user_display_state.dart';

class UserDisplayCubit extends Cubit<UserDisplayState> {
  UserDisplayCubit() : super(const UserDisplayState());

  // Method to update the list of users
  void updateUsers(List<User> users) {
    if (users.isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        filteredUsers: null,
        allUsers: null,
      ));
      return;
    }

    emit(state.copyWith(allUsers: users));
    _processQuery();
  }

  // Method to update search query
  void search(String query) {
    final allUsers = state.allUsers;
    if (allUsers == null || allUsers.isEmpty) {
      emit(state.copyWith(
        searchQuery: query,
        allUsers: null,
      ));
      return;
    }

    emit(state.copyWith(searchQuery: query));
    _processQuery();
  }

  // Method to filter by access level
  void filterByAccessLevel(AccessLevel? accessLevel) {
    emit(state.copyWith(
      accessLevelFilter: accessLevel,
      clearAccessLevelFilter: accessLevel == null,
    ));
    _processQuery();
  }

  // Method to update sort criteria
  void sort(UserDisplaySortBy sortBy) {
    // Check if we're selecting the same sort type that's already active
    if (state.sortBy == sortBy) {
      // Toggle the sort direction if the same sort type is selected again
      emit(state.copyWith(sortAscending: !state.sortAscending));

      // Determine the appropriate sort type based on the field and direction
      final newSortBy = _getSortTypeBasedOnDirection(sortBy, !state.sortAscending);

      emit(state.copyWith(sortBy: newSortBy));
    } else {
      // Default to ascending order for new sort type
      emit(state.copyWith(
        sortBy: sortBy,
        sortAscending: true,
      ));
    }

    _processQuery();
  }

  // Helper method to get the correct sort type based on direction
  UserDisplaySortBy _getSortTypeBasedOnDirection(
    UserDisplaySortBy currentSort,
    bool ascending,
  ) {
    switch (currentSort) {
      case UserDisplaySortBy.nameAscending:
      case UserDisplaySortBy.nameDescending:
        return ascending ? UserDisplaySortBy.nameAscending : UserDisplaySortBy.nameDescending;
      case UserDisplaySortBy.accessLevelAscending:
      case UserDisplaySortBy.accessLevelDescending:
        return ascending
            ? UserDisplaySortBy.accessLevelAscending
            : UserDisplaySortBy.accessLevelDescending;
      case UserDisplaySortBy.creationDateAscending:
      case UserDisplaySortBy.creationDateDescending:
        return ascending
            ? UserDisplaySortBy.creationDateAscending
            : UserDisplaySortBy.creationDateDescending;
      case UserDisplaySortBy.statusAscending:
      case UserDisplaySortBy.statusDescending:
        return ascending ? UserDisplaySortBy.statusAscending : UserDisplaySortBy.statusDescending;
      default:
        return currentSort;
    }
  }

  // Process the query and filter/sort the users
  void _processQuery() {
    final allUsers = state.allUsers;
    if (allUsers == null || allUsers.isEmpty) {
      emit(state.copyWith(filteredUsers: null));
      return;
    }

    // First, filter by access level if needed
    var filteredUsers = allUsers;
    if (state.accessLevelFilter != null) {
      filteredUsers =
          allUsers.where((user) => user.accessLevel == state.accessLevelFilter).toList();
    }

    // Then filter by search query if needed
    final searchQuery = state.searchQuery.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) {
        final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
        final username = user.username.toLowerCase();

        // Simple contains check
        if (fullName.contains(searchQuery) || username.contains(searchQuery)) {
          return true;
        }

        // Levenshtein distance check for fuzzy matching
        final distanceFullName = Levenshtein.distance(fullName, searchQuery);
        final distanceUsername = Levenshtein.distance(username, searchQuery);
        final maxDistance = max(1, searchQuery.length ~/ 3);

        return distanceFullName <= maxDistance || distanceUsername <= maxDistance;
      }).toList();
    }

    // Only show non-archived users by default
    filteredUsers =
        filteredUsers.where((u) => u.archiveStatus == 0 || u.archiveStatus == null).toList();

    // Sort based on the selected sort criteria
    filteredUsers = _sortUsers(filteredUsers);

    emit(state.copyWith(filteredUsers: filteredUsers));
  }

  // Helper method to sort users based on the enum type
  List<User> _sortUsers(List<User> users) {
    final sortedUsers = List<User>.from(users);
    switch (state.sortBy) {
      case UserDisplaySortBy.nameAscending:
        sortedUsers.sort(
            (a, b) => '${a.firstName} ${a.lastName}'.compareTo('${b.firstName} ${b.lastName}'));
        break;
      case UserDisplaySortBy.nameDescending:
        sortedUsers.sort(
            (a, b) => '${b.firstName} ${b.lastName}'.compareTo('${a.firstName} ${a.lastName}'));
        break;
      case UserDisplaySortBy.accessLevelAscending:
        sortedUsers.sort((a, b) => a.accessLevel.index.compareTo(b.accessLevel.index));
        break;
      case UserDisplaySortBy.accessLevelDescending:
        sortedUsers.sort((a, b) => b.accessLevel.index.compareTo(a.accessLevel.index));
        break;
      case UserDisplaySortBy.creationDateAscending:
        sortedUsers.sort((a, b) => a.creationDate.compareTo(b.creationDate));
        break;
      case UserDisplaySortBy.creationDateDescending:
        sortedUsers.sort((a, b) => b.creationDate.compareTo(a.creationDate));
        break;
      case UserDisplaySortBy.statusAscending:
        // Sort by login status (logged in users first)
        sortedUsers.sort((a, b) => (b.loginStatus).compareTo(a.loginStatus));
        break;
      case UserDisplaySortBy.statusDescending:
        // Sort by login status (logged out users first)
        sortedUsers.sort((a, b) => (a.loginStatus).compareTo(b.loginStatus));
        break;
    }
    return sortedUsers;
  }
}
