import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
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
    return const Row(
      children: [
        HeadingText('All Users'),
        Spacer(flex: 2),
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
        Expanded(
          child: TextBox(
            onChanged: (value) {
              context.read<UserDisplayCubit>().search(value);
            },
            placeholder: 'Search',
          ),
        ),
        const Spacer(flex: 2),
        TextButtonFilled('Add User', onPressed: () {
          context.navigate(AppRoutes.admin.createUser);
        }),
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
        return BlocBuilder<UserListBloc, UserListState>(
          builder: (context, state) {
            if (state.status == DataStatus.loading) {
              return const Center(child: ProgressRing());
            }

            final displayCubit = context.read<UserDisplayCubit>();
            final users = displayState.filteredUsers ?? displayState.allUsers;
            final currentUser = context.read<AuthenticationBloc>().state.user!;

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

            // Create a data source for the paginated data table
            final dataSource = _UserDataSource(
                users: users,
                onEditUser: (user) {
                  context.navigateWithExtra(AppRoutes.admin.editUser, user);
                },
                onArchiveUser: currentUser.accessLevel == AccessLevel.administrator
                    ? (user) {
                        context.read<UserListBloc>().add(
                              UpdateUserEvent(
                                user.copyWith(
                                  archiveStatus: user.archiveStatus == 1 ? 0 : 1,
                                ),
                              ),
                            );
                        context
                            .read<UserLogListBloc>()
                            .add(AddArchiveEvent('User ${user.id}', user));
                      }
                    : (user) {});

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
                      label: const Text('Name', overflow: TextOverflow.fade),
                      onSort: (columnIndex, ascending) {
                        displayCubit.sort(
                          ascending
                              ? UserDisplaySortBy.nameAscending
                              : UserDisplaySortBy.nameDescending,
                        );
                      },
                    ),
                    DataColumn(
                      label: const Text('Level of Access', overflow: TextOverflow.fade),
                      onSort: (columnIndex, ascending) {
                        displayCubit.sort(
                          ascending
                              ? UserDisplaySortBy.accessLevelAscending
                              : UserDisplaySortBy.accessLevelDescending,
                        );
                      },
                    ),
                    DataColumn(
                      label: const Text('Creation Date', overflow: TextOverflow.fade),
                      onSort: (columnIndex, ascending) {
                        displayCubit.sort(
                          ascending
                              ? UserDisplaySortBy.creationDateAscending
                              : UserDisplaySortBy.creationDateDescending,
                        );
                      },
                    ),
                    DataColumn(
                      label: const Text('Status', overflow: TextOverflow.fade),
                      onSort: (columnIndex, ascending) {
                        displayCubit.sort(
                          ascending
                              ? UserDisplaySortBy.statusAscending
                              : UserDisplaySortBy.statusDescending,
                        );
                      },
                    ),
                    const DataColumn(
                      label: Text('Actions', overflow: TextOverflow.fade),
                    ),
                  ],
                  source: dataSource,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _UserDataSource extends DataTableSource {
  _UserDataSource({
    required this.users,
    required this.onEditUser,
    required this.onArchiveUser,
  });
  final List<User> users;
  final Function(User) onEditUser;
  final Function(User) onArchiveUser;

  @override
  DataRow getRow(int index) {
    final user = users[index];
    final isLoggedIn = user.loginStatus == 1;

    return DataRowMapper.mapUserToRow(
      user,
      isLoggedIn,
      editAction: () => onEditUser(user),
      archiveFunction: () => onArchiveUser(user),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}
