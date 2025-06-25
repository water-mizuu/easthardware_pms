part of 'archived_user_display_cubit.dart';

class ArchivedUserDisplayState extends Equatable {
  final List<User> allUsers;
  final List<User> filteredUsers;
  final ArchivedUserSortBy sortBy;
  final bool sortAscending;

  const ArchivedUserDisplayState({
    this.allUsers = const [],
    this.filteredUsers = const [],
    this.sortBy = ArchivedUserSortBy.idAscending,
    this.sortAscending = true,
  });

  ArchivedUserDisplayState copyWith({
    List<User>? allUsers,
    List<User>? filteredUsers,
    ArchivedUserSortBy? sortBy,
    bool? sortAscending,
  }) {
    return ArchivedUserDisplayState(
      allUsers: allUsers ?? this.allUsers,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  @override
  List<Object?> get props => [allUsers, filteredUsers, sortBy, sortAscending];
}
