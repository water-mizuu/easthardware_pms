part of 'user_log_list_bloc.dart';

sealed class UserLogListEvent {
  const UserLogListEvent();
}

class LoadUserLogsEvent implements UserLogListEvent {
  const LoadUserLogsEvent();
}

class _FilterUserLogsEvent implements UserLogListEvent {
  const _FilterUserLogsEvent();
}

class SearchQueryUpdatedEvent implements UserLogListEvent {
  const SearchQueryUpdatedEvent(this.query);

  final String query;
}

class AccessLevelQueryUpdatedEvent implements UserLogListEvent {
  const AccessLevelQueryUpdatedEvent(this.accessLevel);

  final AccessLevel? accessLevel;
}

class StartDateQueryUpdatedEvent implements UserLogListEvent {
  const StartDateQueryUpdatedEvent(this.startDate);

  final DateTime? startDate;
}

class EndDateQueryUpdatedEvent implements UserLogListEvent {
  const EndDateQueryUpdatedEvent(this.endDate);

  final DateTime? endDate;
}

class AddCreateEvent implements UserLogListEvent {
  const AddCreateEvent(this.item, this.user);

  final String item;
  final User user;
}

class AddLoginEvent implements UserLogListEvent {
  const AddLoginEvent(this.user);

  final User user;
}

class AddLogoutEvent implements UserLogListEvent {
  const AddLogoutEvent(this.user);

  final User user;
}

class AddUpdateEvent implements UserLogListEvent {
  const AddUpdateEvent(this.item, this.user);

  final String item;
  final User user;
}

class AddArchiveEvent implements UserLogListEvent {
  const AddArchiveEvent(this.item, this.user);

  final String item;
  final User user;
}

class UpdateUserLogEvent implements UserLogListEvent {
  const UpdateUserLogEvent(this.userLog);

  final UserLog userLog;
}

class DeleteUserLogEvent implements UserLogListEvent {
  const DeleteUserLogEvent(this.userLog);

  final UserLog userLog;
}

class CreateBackupEvent implements UserLogListEvent {
  const CreateBackupEvent(this.user);

  final User user;
}

class RestoreBackupEvent implements UserLogListEvent {
  const RestoreBackupEvent(this.user);

  final User user;
}
