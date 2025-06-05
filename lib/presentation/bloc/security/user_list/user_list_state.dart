part of 'user_list_bloc.dart';

class UserListState extends Equatable {
  const UserListState({
    this.users = const [],
    this.filteredUsers = const [],
    this.status = DataStatus.initial,
    this.searchQuery,
    this.accessLevelQuery,
  });

  final List<User> users;
  final List<User> filteredUsers;
  final String? searchQuery;
  final AccessLevel? accessLevelQuery;
  final DataStatus status;

  UserListState Function({
    List<User> users,
    List<User> filteredUsers,
    String? searchQuery,
    AccessLevel? accessLevelQuery,
    DataStatus status,
  }) get copyWith {
    return ({
      Object? users = undefined,
      Object? filteredUsers = undefined,
      Object? searchQuery = undefined,
      Object? accessLevelQuery = undefined,
      Object? status = undefined,
    }) {
      return UserListState(
        users: users.or(this.users),
        filteredUsers: filteredUsers.or(this.filteredUsers),
        searchQuery: searchQuery.or(this.searchQuery),
        accessLevelQuery: accessLevelQuery.or(this.accessLevelQuery),
        status: status.or(this.status),
      );
    };
  }

  @override
  List<Object?> get props => [users, status, searchQuery, accessLevelQuery, filteredUsers];
}
