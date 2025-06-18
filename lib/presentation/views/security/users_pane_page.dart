import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, DataTable;
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersPanePage extends StatelessWidget {
  const UsersPanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          PageHeader(),
          PageActions(),
          Expanded(child: UserDataTable()),
        ].withSpacing(() => Spacing.v16),
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
        ComboBox(
          placeholder: const Text('Filter by Level'),
          value: context.select((UserListBloc b) => b.state.accessLevelQuery),
          onChanged: (value) {
            context.read<UserListBloc>().add(FilterUsersByAccessLevelEvent(value));
          },
          items: [
            const ComboBoxItem(value: null, child: Text('All Users')),
            for (final accessLevel in AccessLevel.values)
              ComboBoxItem(value: accessLevel, child: Text(accessLevel.toString())),
          ],
        ),
        Expanded(
          child: TextBox(
            onChanged: (value) {
              context.read<UserListBloc>().add(SearchUsersByStringEvent(value));
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

  @override
  Widget build(BuildContext context) {
    final allUsers = context.select((UserListBloc b) => b.state.filteredUsers);
    final notArchivedUsers = allUsers //
        .where((u) => u.archiveStatus == 0 || u.archiveStatus == null)
        .toList();

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name', overflow: TextOverflow.fade)),
          DataColumn(label: Text('Level of Access', overflow: TextOverflow.fade)),
          DataColumn(label: Text('Creation Date', overflow: TextOverflow.fade)),
          DataColumn(label: Text('Status', overflow: TextOverflow.fade)),
        ],
        rows: [
          for (final user in notArchivedUsers) //
            DataRowMapper.mapUserToRow(user, user.loginStatus == 1),
        ],
      ),
    );
  }
}
