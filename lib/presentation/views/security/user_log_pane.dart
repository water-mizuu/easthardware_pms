import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/userlist/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/userloglist/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/data_table_place_holder.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/helper/route_index_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, DataTable;
import 'package:flutter_bloc/flutter_bloc.dart';

class UserLogPane extends StatelessWidget {
  const UserLogPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(),
          const PageActions(),
          const UserLogDataTable(),
        ].withSpacing(() => Spacing.v16),
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
        IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () {
            var event = NavigationIndexChanged(
              index: RouteIndexMapper.getIndexFromRoute(AppRoutes.usersPage)!,
            );

            context.read<NavigationBloc>().add(event);
          },
        ),
        const HeadingText('User Logs'),
      ].withSpacing(() => Spacing.h16),
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
          placeholder: Text('Level of Access'),
          items: [],
        ),
        const Expanded(child: TextBox(placeholder: 'Search')),
        // Column(
        //   children: [
        //     const CaptionText('From Date'),
        //     DatePicker(selected: null),
        //   ],
        // ),
        // Column(
        //   children: [
        //     const CaptionText('To Date'),
        //     DatePicker(selected: null),
        //   ],
        // ),
        const Spacer(flex: 2),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class UserLogDataTable extends StatelessWidget {
  const UserLogDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserListBloc, UserListState>(
      builder: (context, state) {
        final allUsers = state.users;
        return BlocBuilder<UserLogListBloc, UserLogListState>(
          builder: (context, state) {
            switch (state.status) {
              case DataStatus.loading:
                return const Expanded(
                    child: Center(
                  child: ProgressRing(),
                ));
              default:
                final allLogs = state.userlogs;
                if (allLogs.isEmpty) {
                  return const DataTablePlaceHolder(FluentIcons.activity_feed, 'Logs');
                }
                return Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('User')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: allLogs
                          .map((log) => DataRowMapper.mapUserLogToRow(
                              log, allUsers.firstWhere((user) => user.id == log.userId)))
                          .toList(),
                    ),
                  ),
                );
            }
          },
        );
      },
    );
  }
}
