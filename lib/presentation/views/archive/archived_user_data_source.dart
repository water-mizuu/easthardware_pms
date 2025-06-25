import 'package:easthardware_pms/domain/models/user.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:flutter/material.dart' show DataCell, DataRow, DataTableSource, Text;

class ArchivedUserDataSource extends DataTableSource {
  ArchivedUserDataSource({
    required this.users,
  });

  final List<User> users;

  @override
  DataRow? getRow(int index) {
    final user = users[index];

    return DataRow(cells: [
      DataCell(Text(user.id.toString(), style: TextStyles.body)),
      DataCell(Text(user.username, style: TextStyles.body)),
      DataCell(Text('${user.firstName} ${user.lastName}', style: TextStyles.body)),
      DataCell(Text(user.accessLevel.toString(), style: TextStyles.body)),
      DataCell(Text(user.creationDate, style: TextStyles.body)),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}
