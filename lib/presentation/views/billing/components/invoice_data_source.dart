import 'dart:async';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/views/billing/components/invoice_information_content_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataRow, DataTableSource;
import 'package:intl/intl.dart';

class InvoiceDataSource extends DataTableSource {
  InvoiceDataSource({
    required this.invoices,
    required this.context,
    required this.onSort,
  });

  final List<Invoice> invoices;
  final BuildContext context;
  final void Function(InvoiceDisplaySortBy) onSort;

  final currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  final dateFormat = DateFormat('MM/dd/yyyy');

  @override
  DataRow? getRow(int index) {
    if (index >= invoices.length) return null;
    final invoice = invoices[index];

    return DataRowMapper.mapInvoiceToRow(
      invoice,
      viewAction: () {
        unawaited(
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (context) => InvoiceInformationContentDialog(
              context: context,
              invoice: invoice,
            ),
          ),
        );
      },
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => invoices.length;

  @override
  int get selectedRowCount => 0;
}
