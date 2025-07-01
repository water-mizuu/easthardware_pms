import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/views/security/user_information_content_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataCell, DataRow, DataTableSource, Text;
import 'package:flutter_bloc/flutter_bloc.dart';

class ArchivedUserDataSource extends DataTableSource {
  ArchivedUserDataSource({
    required this.users,
    required this.context,
  });

  final BuildContext context;
  final List<User> users;

  void viewUser(User user) {
    final currentUser = context.read<AuthenticationBloc>().state.user!;
    showDialog(
      context: context,
      builder: (dialogContext) => UserInformationContentDialog(
        user: user,
        dialogContext: dialogContext,
        currentUser: currentUser,
      ),
    );
  }

  @override
  DataRow getRow(int index) {
    final user = users[index];

    return DataRow(
      cells: [
        DataCell(Text(user.id.toString(), style: TextStyles.body)),
        DataCell(Text(user.username, style: TextStyles.body)),
        DataCell(Text('${user.firstName} ${user.lastName}', style: TextStyles.body)),
        DataCell(Text(user.accessLevel.toString(), style: TextStyles.body)),
        DataCell(Text(user.creationDate, style: TextStyles.body)),
      ],
      onSelectChanged: (_) => viewUser(user),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}
