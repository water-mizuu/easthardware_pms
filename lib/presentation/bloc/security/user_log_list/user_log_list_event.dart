part of 'user_log_list_bloc.dart';

sealed class UserLogListEvent extends Equatable {
  const UserLogListEvent();

  @override
  List<Object> get props => [];
}

class LoadUserLogsEvent extends UserLogListEvent {}

class FilterUserLogsEvent extends UserLogListEvent {
  final int id;

  const FilterUserLogsEvent(this.id);
}

class AddCreateEvent extends UserLogListEvent {
  final String item;
  final User user;
  const AddCreateEvent(this.item, this.user);
}

class AddLoginEvent extends UserLogListEvent {
  final User user;

  const AddLoginEvent(this.user);
}

class AddLogoutEvent extends UserLogListEvent {
  final User user;

  const AddLogoutEvent(this.user);
}

class AddUpdateEvent extends UserLogListEvent {
  final String item;
  final User user;
  const AddUpdateEvent(this.item, this.user);
}

class AddArchiveEvent extends UserLogListEvent {
  final String item;
  final User user;
  const AddArchiveEvent(this.item, this.user);
}

class UpdateUserLogEvent extends UserLogListEvent {
  final UserLog userLog;

  const UpdateUserLogEvent(this.userLog);
}

class DeleteUserLogEvent extends UserLogListEvent {
  final UserLog userLog;

  const DeleteUserLogEvent(this.userLog);
}
