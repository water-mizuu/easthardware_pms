part of 'user_list_bloc.dart';

sealed class UserListEvent extends Equatable {
  const UserListEvent();

  @override
  List<Object> get props => [];
}

class LoadAllUsersEvent extends UserListEvent {}

class AddUserEvent extends UserListEvent {
  final User user;

  const AddUserEvent(this.user);
}

class UpdateUserEvent extends UserListEvent {
  final User user;

  const UpdateUserEvent(this.user);
}

class DeleteUserEevnt extends UserListEvent {
  final User user;

  const DeleteUserEevnt(this.user);
}
