part of 'user_display_cubit.dart';

enum UserDisplaySortBy {
  nameAscending,
  nameDescending,
  accessLevelAscending,
  accessLevelDescending,
  creationDateAscending,
  creationDateDescending,
  statusAscending,
  statusDescending,
}

class UserDisplayState extends Equatable {
  const UserDisplayState({
    this.searchQuery = '',
    this.sortBy = UserDisplaySortBy.nameAscending,
    this.sortAscending = true,
    this.allUsers,
    this.filteredUsers,
    this.accessLevelFilter,
  });
  final String searchQuery;
  final UserDisplaySortBy sortBy;
  final bool sortAscending;
  final List<User>? allUsers;
  final List<User>? filteredUsers;
  final AccessLevel? accessLevelFilter;

  UserDisplayState copyWith({
    String? searchQuery,
    UserDisplaySortBy? sortBy,
    bool? sortAscending,
    List<User>? allUsers,
    List<User>? filteredUsers,
    AccessLevel? accessLevelFilter,
    bool clearAccessLevelFilter = false,
  }) {
    return UserDisplayState(
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      allUsers: allUsers ?? this.allUsers,
      filteredUsers: filteredUsers,
      accessLevelFilter:
          clearAccessLevelFilter ? null : accessLevelFilter ?? this.accessLevelFilter,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        sortBy,
        sortAscending,
        allUsers,
        filteredUsers,
        accessLevelFilter,
      ];
}
