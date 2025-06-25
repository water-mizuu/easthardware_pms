import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/presentation/cubit/archive/archive_sort_enums.dart';
import 'package:equatable/equatable.dart';

part 'archived_user_display_state.dart';

class ArchivedUserDisplayCubit extends Cubit<ArchivedUserDisplayState> {
  ArchivedUserDisplayCubit() : super(const ArchivedUserDisplayState());

  void updateUsers(List<User> users) {
    emit(state.copyWith(allUsers: users, filteredUsers: users));
  }

  void filterUsers(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(filteredUsers: state.allUsers));
    } else {
      final filteredUsers = state.allUsers
          .where((user) =>
              user.username.toLowerCase().contains(query.toLowerCase()) ||
              user.firstName.toLowerCase().contains(query.toLowerCase()) ||
              user.lastName.toLowerCase().contains(query.toLowerCase()) ||
              '${user.firstName} ${user.lastName}'.toLowerCase().contains(query.toLowerCase()))
          .toList();
      emit(state.copyWith(filteredUsers: filteredUsers));
    }
  }

  void sort(ArchivedUserSortBy sortBy) {
    final users = List<User>.from(state.filteredUsers);
    bool sortAscending = true;

    switch (sortBy) {
      case ArchivedUserSortBy.idAscending:
        users.sort((a, b) => a.id!.compareTo(b.id!));
        sortBy = ArchivedUserSortBy.idDescending;
        break;
      case ArchivedUserSortBy.idDescending:
        users.sort((a, b) => b.id!.compareTo(a.id!));
        sortBy = ArchivedUserSortBy.idAscending;
        sortAscending = false;
        break;
      case ArchivedUserSortBy.usernameAscending:
        users.sort((a, b) => a.username.compareTo(b.username));
        sortBy = ArchivedUserSortBy.usernameDescending;
        break;
      case ArchivedUserSortBy.usernameDescending:
        users.sort((a, b) => b.username.compareTo(a.username));
        sortBy = ArchivedUserSortBy.usernameAscending;
        sortAscending = false;
        break;
      case ArchivedUserSortBy.nameAscending:
        users.sort(
            (a, b) => '${a.firstName} ${a.lastName}'.compareTo('${b.firstName} ${b.lastName}'));
        sortBy = ArchivedUserSortBy.nameDescending;
        break;
      case ArchivedUserSortBy.nameDescending:
        users.sort(
            (a, b) => '${b.firstName} ${b.lastName}'.compareTo('${a.firstName} ${a.lastName}'));
        sortBy = ArchivedUserSortBy.nameAscending;
        sortAscending = false;
        break;
      case ArchivedUserSortBy.accessLevelAscending:
        users.sort((a, b) => a.accessLevel.toString().compareTo(b.accessLevel.toString()));
        sortBy = ArchivedUserSortBy.accessLevelDescending;
        break;
      case ArchivedUserSortBy.accessLevelDescending:
        users.sort((a, b) => b.accessLevel.toString().compareTo(a.accessLevel.toString()));
        sortBy = ArchivedUserSortBy.accessLevelAscending;
        sortAscending = false;
        break;
      case ArchivedUserSortBy.creationDateAscending:
        users.sort((a, b) => a.creationDate.compareTo(b.creationDate));
        sortBy = ArchivedUserSortBy.creationDateDescending;
        break;
      case ArchivedUserSortBy.creationDateDescending:
        users.sort((a, b) => b.creationDate.compareTo(a.creationDate));
        sortBy = ArchivedUserSortBy.creationDateAscending;
        sortAscending = false;
        break;
    }

    emit(state.copyWith(
      filteredUsers: users,
      sortBy: sortBy,
      sortAscending: sortAscending,
    ));
  }
}
