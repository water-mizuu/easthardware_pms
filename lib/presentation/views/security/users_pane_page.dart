import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/buttons/text_button.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/helper/route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
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
          UserDataTable(),
        ].withSpacing(
          () => Spacing.v16,
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
        const ComboBox(
          placeholder: Text('Filter by Level'),
          items: [],
        ),
        const Expanded(child: TextBox()),
        const Spacer(flex: 2),
        TextButtonFilled('Add User', onPressed: () {
          const route = AppRoutes.createUserPage;
          context
              .read<NavigationBloc>()
              .add(NavigationIndexChanged(index: RouteIndexMapper.getIndexFromRoute(route)!));
        }),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class UserDataTable extends StatelessWidget {
  const UserDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserListBloc, UserListState>(builder: (context, state) {
      switch (state.status) {
        case DataStatus.loading:
          return const Expanded(child: Center(child: ProgressRing()));
        default:
          final allUsers = state.users.where((user) => user.status == 0).toList();
          return Expanded(
            child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Level of Access')),
                      DataColumn(label: Text('Creation Date')),
                    ],
                    rows: allUsers.map((user) {
                      return DataRowMapper.mapUserToRow(user, () {});
                    }).toList())),
          );
      }
    });
  }
}
