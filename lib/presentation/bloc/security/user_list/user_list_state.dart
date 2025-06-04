part of 'user_list_bloc.dart';

class UserListState extends Equatable {
  const UserListState({
    this.users = const [],
    this.status = DataStatus.initial,
  });

  final List<User> users;
  final DataStatus status;

  UserListState Function({
    List<User>? users,
    List<int>? loggedInUserIds,
    DataStatus? status,
  }) get copyWith {
    return ({
      Object? users = undefined,
      Object? loggedInUserIds = undefined,
      Object? status = undefined,
    }) {
      return UserListState(
        users: users.or(this.users),
        status: status.or(this.status),
      );
    };
  }

  @override
  List<Object> get props => [users, status];
}
