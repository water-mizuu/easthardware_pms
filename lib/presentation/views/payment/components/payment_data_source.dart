import 'package:easthardware_pms/domain/models/payment.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataCell, DataRow, DataTableSource;
import 'package:intl/intl.dart';

class PaymentDataSource extends DataTableSource {
  PaymentDataSource({
    required this.payments,
    required this.paymentMethods,
    this.onEdit,
    this.onDelete,
    this.context,
  });

  final List<(Payment, String)> payments;
  final List<PaymentMethod> paymentMethods;
  final Function(Payment)? onEdit;
  final Function(Payment)? onDelete;
  final BuildContext? context;

  String getPaymentMethodName(int paymentMethodId) {
    final method = paymentMethods.firstWhere(
      (method) => method.id == paymentMethodId,
      orElse: () => PaymentMethod(id: -1, name: 'Unknown'),
    );
    return method.name;
  }

  @override
  DataRow? getRow(int index) {
    if (index >= payments.length) return null;

    final payment = payments[index];
    final formatter = NumberFormat.currency(symbol: 'Php ', decimalDigits: 2);
    final dateFormatter = DateFormat('MMM dd, yyyy');

    return DataRow(
      cells: [
        DataCell(Text(
          dateFormatter.format(payment.$1.paymentDate),
          style: TextStyles.body,
        )),
        DataCell(Text(
          payment.$2,
          style: TextStyles.body,
        )),
        DataCell(Text(
          formatter.format(payment.$1.amount),
          style: TextStyles.body,
        )),
        DataCell(Text(
          payment.$1.referenceNumber,
          style: TextStyles.body,
        )),
        DataCell(Text(
          getPaymentMethodName(payment.$1.paymentMethod),
          style: TextStyles.body,
        )),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                IconButton(
                  icon: const Icon(FluentIcons.edit),
                  onPressed: () => onEdit!(payment.$1),
                ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(FluentIcons.delete),
                  onPressed: () => onDelete!(payment.$1),
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
  int get rowCount => payments.length;

  @override
  int get selectedRowCount => 0;
}
