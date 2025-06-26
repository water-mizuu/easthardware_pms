import 'package:easthardware_pms/presentation/cubit/order/expense_type_display/display_expense_type.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

class ExpenseTypeDataSource extends DataTableSource {
  ExpenseTypeDataSource({
    required this.context,
    required this.expenseTypes,
    required this.onEdit,
  });

  final List<DisplayExpenseType> expenseTypes;
  final BuildContext context;
  final Function(DisplayExpenseType) onEdit;

  @override
  DataRow? getRow(int index) {
    final expenseType = expenseTypes[index];

    return DataRow(
      onSelectChanged: (_) {
        // View expense type details if needed
      },
      cells: [
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(expenseType.expenseType.id.toString()),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(expenseType.expenseType.name),
          ),
        ),
        DataCell(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(expenseType.orderCount.toString()),
          ),
        ),
        DataCell(
          Row(
            children: [
              // Only show edit button if it's not a system expense type (id 1)
              if (expenseType.expenseType.id != 1)
                fluent.Button(
                  child: const Text('Edit'),
                  onPressed: () => onEdit(expenseType),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => expenseTypes.length;

  @override
  int get selectedRowCount => 0;
}
