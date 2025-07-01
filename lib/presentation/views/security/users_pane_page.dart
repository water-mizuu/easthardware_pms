import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/security/user_display/user_display_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/table_theme_data.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart'
    show DataColumn, DataRow, DataTableSource, PaginatedDataTable;
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersPanePage extends StatefulWidget {
  const UsersPanePage({super.key});

  @override
  State<UsersPanePage> createState() => _UsersPanePageState();
}

class _UsersPanePageState extends State<UsersPanePage> {
  @override
  void initState() {
    super.initState();
    // Get users from the user list bloc
    context.read<UserDisplayCubit>().updateUsers(
          context.read<UserListBloc>().state.users,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserListBloc, UserListState>(
      listenWhen: (previous, current) => previous.users != current.users,
      listener: (context, state) {
        context.read<UserDisplayCubit>().updateUsers(state.users);
      },
      child: Padding(
        padding: AppPadding.panePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            PageHeader(),
            PageActions(),
            Expanded(child: UserDataTable()),
          ].withSpacing(() => Spacing.v16),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HeadingText('All Users'),
        const Spacer(flex: 2),
        TextButtonFilled('Add User', onPressed: () {
          context.navigate(AppRoutes.admin.createUser);
        }),
      ],
    );
  }
}

class PageActions extends StatelessWidget {
  const PageActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextBox(
            onChanged: (value) {
              context.read<UserDisplayCubit>().search(value);
            },
            placeholder: 'Search',
          ),
        ),
        ComboBox<AccessLevel?>(
          placeholder: const Text('Filter by Level'),
          value: context.select((UserDisplayCubit c) => c.state.accessLevelFilter),
          onChanged: (value) {
            context.read<UserDisplayCubit>().filterByAccessLevel(value);
          },
          items: [
            const ComboBoxItem(value: null, child: Text('All Users')),
            for (final accessLevel in AccessLevel.values)
              ComboBoxItem(value: accessLevel, child: Text(accessLevel.name.toTitleCase())),
          ],
        ),
        const Spacer(flex: 2),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class UserDataTable extends StatelessWidget {
  const UserDataTable({super.key});

  int? _getSortColumnIndex(UserDisplaySortBy sortBy) {
    switch (sortBy) {
      case UserDisplaySortBy.nameAscending:
      case UserDisplaySortBy.nameDescending:
        return 0;
      case UserDisplaySortBy.accessLevelAscending:
      case UserDisplaySortBy.accessLevelDescending:
        return 1;
      case UserDisplaySortBy.creationDateAscending:
      case UserDisplaySortBy.creationDateDescending:
        return 2;
      case UserDisplaySortBy.statusAscending:
      case UserDisplaySortBy.statusDescending:
        return 3;
      default:
        return null;
    }
  }

  bool _getSortAscending(UserDisplaySortBy sortBy) {
    switch (sortBy) {
      case UserDisplaySortBy.nameAscending:
      case UserDisplaySortBy.accessLevelAscending:
      case UserDisplaySortBy.creationDateAscending:
      case UserDisplaySortBy.statusAscending:
        return true;
      case UserDisplaySortBy.nameDescending:
      case UserDisplaySortBy.accessLevelDescending:
      case UserDisplaySortBy.creationDateDescending:
      case UserDisplaySortBy.statusDescending:
        return false;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserDisplayCubit, UserDisplayState>(
      builder: (context, displayState) {
        final displayCubit = context.read<UserDisplayCubit>();
        final users = displayState.filteredUsers ?? displayState.allUsers;

        if (users == null || users.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text('No users found', style: TextStyles.body),
            ),
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: TableThemeData(
            child: PaginatedDataTable(
                sortColumnIndex: _getSortColumnIndex(displayState.sortBy),
                sortAscending: _getSortAscending(displayState.sortBy),
                rowsPerPage: 10,
                availableRowsPerPage: const [5, 10, 20, 50],
                columns: [
                  DataColumn(
                    label: Expanded(
                        child: Row(
                      children: [
                        const Text('Name', overflow: TextOverflow.fade),
                        if (_getSortColumnIndex(displayState.sortBy) != 0) ...[
                          const Spacer(),
                          const Icon(
                            FluentIcons.scroll_up_down,
                            size: 12,
                          ),
                        ],
                      ],
                    )),
                    onSort: (_, __) {
                      if (displayState.sortBy == UserDisplaySortBy.nameAscending ||
                          displayState.sortBy == UserDisplaySortBy.nameDescending) {
                        displayCubit.sort(displayState.sortBy);
                      } else {
                        displayCubit.sort(UserDisplaySortBy.nameAscending);
                      }
                    },
                  ),
                  DataColumn(
                    label: Expanded(
                        child: Row(
                      children: [
                        const Text('Level of Access', overflow: TextOverflow.fade),
                        if (_getSortColumnIndex(displayState.sortBy) != 1) ...[
                          const Spacer(),
                          const Icon(
                            FluentIcons.scroll_up_down,
                            size: 12,
                          ),
                        ],
                      ],
                    )),
                    onSort: (_, __) {
                      if (displayState.sortBy == UserDisplaySortBy.accessLevelAscending ||
                          displayState.sortBy == UserDisplaySortBy.accessLevelDescending) {
                        displayCubit.sort(displayState.sortBy);
                      } else {
                        displayCubit.sort(UserDisplaySortBy.accessLevelAscending);
                      }
                    },
                  ),
                  DataColumn(
                    label: Expanded(
                        child: Row(
                      children: [
                        const Text('Creation Date', overflow: TextOverflow.fade),
                        if (_getSortColumnIndex(displayState.sortBy) != 2) ...[
                          const Spacer(),
                          const Icon(
                            FluentIcons.scroll_up_down,
                            size: 12,
                          ),
                        ],
                      ],
                    )),
                    onSort: (_, __) {
                      if (displayState.sortBy == UserDisplaySortBy.creationDateAscending ||
                          displayState.sortBy == UserDisplaySortBy.creationDateDescending) {
                        displayCubit.sort(displayState.sortBy);
                      } else {
                        displayCubit.sort(UserDisplaySortBy.creationDateAscending);
                      }
                    },
                  ),
                  DataColumn(
                    label: Expanded(
                      child: Row(
                        children: [
                          const Text('Status', overflow: TextOverflow.fade),
                          if (_getSortColumnIndex(displayState.sortBy) != 3) ...[
                            const Spacer(),
                            const Icon(
                              FluentIcons.scroll_up_down,
                              size: 12,
                            ),
                          ],
                        ],
                      ),
                    ),
                    onSort: (_, __) {
                      if (displayState.sortBy == UserDisplaySortBy.statusAscending ||
                          displayState.sortBy == UserDisplaySortBy.statusDescending) {
                        displayCubit.sort(displayState.sortBy);
                      } else {
                        displayCubit.sort(UserDisplaySortBy.statusAscending);
                      }
                    },
                  ),
                  const DataColumn(
                    label: Expanded(child: Text('Actions', overflow: TextOverflow.fade)),
                  ),
                ],
                source: UserDataSource(context: context, users: users)),
          ),
        );
      },
    );
  }
}

class UserDataSource extends DataTableSource {
  UserDataSource({
    required this.context,
    required this.users,
  });

  final BuildContext context;
  late final List<User> users;

  void editUser(User user) {
    context.navigateWithExtra(AppRoutes.admin.editUser, user);
  }

  void archiveUser(User user) {
    context.read<UserListBloc>().add(ArchiveUserEvent(user));
  }

  @override
  DataRow getRow(int index) {
    final currentUser = context.read<AuthenticationBloc>().state.user!;
    final user = users[index];
    final isLoggedIn = user.loginStatus == 1;
    final isOwnAccount = user.id == currentUser.id;
    final isAnAdministrator = currentUser.accessLevel == AccessLevel.administrator;

    return DataRowMapper.mapUserToRow(
      user,
      isLoggedIn,
      editAction: isOwnAccount ? editUser : null,
      archiveFunction: isAnAdministrator && !isOwnAccount ? archiveUser : null,
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}
