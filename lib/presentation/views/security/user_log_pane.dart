import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_list/user_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/data_table_place_holder.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, DataTable;
import 'package:provider/provider.dart';

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
            context.navigate(AppRoutes.admin.users);
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
        /// Wrap the thing in a builder to avoid rerendering the entire widget
        ///   and localize the changes to just the ComboBox.
        Selector(
          selector: (_, UserLogListBloc bloc) => bloc.state.queryData.accessLevel,
          builder: (context, accessLevel, _) {
            return ComboBox<AccessLevel?>(
              value: context.select((UserLogListBloc b) => b.state.queryData.accessLevel),
              onChanged: (value) {
                context.read<UserLogListBloc>().add(AccessLevelQueryUpdatedEvent(value));
              },
              placeholder: const Text('Level of Access'),
              items: [
                const ComboBoxItem(value: null, child: Text('All')),
                for (final accessLevel in AccessLevel.values)
                  ComboBoxItem(value: accessLevel, child: Text(accessLevel.toString())),
              ],
            );
          },
        ),
        Expanded(
          child: TextBox(
            placeholder: 'Search',
            onChanged: (value) {
              context.read<UserLogListBloc>().add(SearchQueryUpdatedEvent(value));
            },
          ),
        ),
        Column(
          children: [
            const CaptionText('From Date'),
            Selector(
              selector: (_, UserLogListBloc b) => b.state.queryData.startDate,
              builder: (context, startDate, _) {
                return DatePicker(
                  selected: startDate,
                  onChanged: (value) {
                    context.read<UserLogListBloc>().add(StartDateQueryUpdatedEvent(value));
                  },
                );
              },
            ),
          ],
        ),
        Column(
          children: [
            const CaptionText('To Date'),
            Selector(
              selector: (_, UserLogListBloc bloc) => bloc.state.queryData.endDate,
              builder: (context, endDate, _) {
                return DatePicker(
                  selected: endDate,
                  onChanged: (value) {
                    context.read<UserLogListBloc>().add(EndDateQueryUpdatedEvent(value));
                  },
                );
              },
            ),
          ],
        ),
        const Spacer(flex: 2),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class UserLogDataTable extends StatelessWidget {
  const UserLogDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    final allUsers = context.watch<UserListBloc>().state.users;
    final memo = <int, User?>{};

    /// Finds a user by their ID, memoizing the result for performance.
    /// If the user is not found in the memo, it searches through all users.
    User? findUserById(int id) {
      if (!memo.containsKey(id)) {
        memo[id] = allUsers.where((user) => user.id == id).firstOrNull;
      }
      return memo[id]!;
    }

    final state = context.watch<UserLogListBloc>().state;
    switch (state.status) {
      case DataStatus.loading:
        return const Expanded(
          child: Center(
            child: ProgressRing(),
          ),
        );
      default:
        final filteredLogs = state.filteredLogs;
        if (filteredLogs.isEmpty) {
          return const DataTablePlaceHolder(FluentIcons.activity_feed, 'Logs');
        }
        return Expanded(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Colors.white),
            child: AnimatedSingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('Action')),
                ],
                rows: [
                  for (final log in filteredLogs.reversed)
                    if (findUserById(log.userId) case final user?)
                      DataRowMapper.mapUserLogToRow(log, user),
                ],
              ),
            ),
          ),
        );
    }
  }
}
