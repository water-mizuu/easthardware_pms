import 'dart:async';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/billing/components/invoice_information_content_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataRow, DataTableSource;
import 'package:flutter_bloc/flutter_bloc.dart';
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
      editAction:
          context.read<AuthenticationBloc>().state.user?.accessLevel == AccessLevel.administrator
              ? () {
                  context.navigateWithExtra(AppRoutes.admin.editInvoice, invoice);
                }
              : () {
                  context.navigateWithExtra(AppRoutes.staff.editInvoice, invoice);
                },
      printAction:
          context.read<AuthenticationBloc>().state.user?.accessLevel == AccessLevel.administrator
              ? () {
                  // context.navigateWithExtra(AppRoutes.admin.printInvoice, invoice);
                }
              : () {},
      receivePaymentAction:
          context.read<AuthenticationBloc>().state.user?.accessLevel == AccessLevel.administrator
              ? () {
                  context.navigateWithExtra(AppRoutes.admin.createPayment.withInvoice, invoice);
                }
              : () {
                  context.navigateWithExtra(AppRoutes.staff.createPayment.withInvoice, invoice);
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
