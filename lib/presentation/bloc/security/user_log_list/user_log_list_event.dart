part of 'user_log_list_bloc.dart';

sealed class UserLogListEvent {
  const UserLogListEvent();
}

class LoadUserLogsEvent with EquatableMixin implements UserLogListEvent {
  const LoadUserLogsEvent();

  @override
  List<Object?> get props => [];
}

class FilterUserLogsEvent with EquatableMixin implements UserLogListEvent {
  const FilterUserLogsEvent(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class AddCreateEvent with EquatableMixin implements UserLogListEvent {
  const AddCreateEvent(this.item, this.user);

  final String item;
  final User user;

  @override
  List<Object?> get props => [item, user];
}

class AddLoginEvent with EquatableMixin implements UserLogListEvent {
  const AddLoginEvent(this.user);
  final User user;

  @override
  List<Object?> get props => [user];
}

class AddLogoutEvent with EquatableMixin implements UserLogListEvent {
  const AddLogoutEvent(this.user);
  final User user;

  @override
  List<Object?> get props => [user];
}

class AddUpdateEvent with EquatableMixin implements UserLogListEvent {
  const AddUpdateEvent(this.item, this.user);
  final String item;
  final User user;

  @override
  List<Object?> get props => [item, user];
}

class AddArchiveEvent with EquatableMixin implements UserLogListEvent {
  const AddArchiveEvent(this.item, this.user);
  final String item;
  final User user;

  @override
  List<Object?> get props => [item, user];
}

class UpdateUserLogEvent with EquatableMixin implements UserLogListEvent {
  const UpdateUserLogEvent(this.userLog);
  final UserLog userLog;

  @override
  List<Object?> get props => [userLog];
}

class DeleteUserLogEvent with EquatableMixin implements UserLogListEvent {
  const DeleteUserLogEvent(this.userLog);
  final UserLog userLog;

  @override
  List<Object?> get props => [userLog];
}
