part of 'user_list_bloc.dart';

sealed class UserListEvent extends Equatable {
  const UserListEvent();

  @override
  List<Object> get props => [];
}

class LoadAllUsersEvent extends UserListEvent {
  const LoadAllUsersEvent();
}

class AddUserEvent extends UserListEvent {
  const AddUserEvent(this.user);
  final User user;
}

class UpdateUserEvent extends UserListEvent {
  const UpdateUserEvent(this.user);
  final User user;
}

class DeleteUserEvent extends UserListEvent {
  const DeleteUserEvent(this.user);
  final User user;
}

class FilterUsersByAccessLevelEvent extends UserListEvent {
  const FilterUsersByAccessLevelEvent(this.accessLevelQuery);
  final AccessLevel? accessLevelQuery;
}

class SearchUsersByStringEvent extends UserListEvent {
  const SearchUsersByStringEvent(this.searchQuery);
  final String searchQuery;
}

class UserLoggedInEvent extends UserListEvent {
  const UserLoggedInEvent(this.userId);
  final int userId;
}

class UserLoggedOutEvent extends UserListEvent {
  const UserLoggedOutEvent(this.userId);
  final int userId;
}
