import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/category_list/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/billing/components/invoice_information_content_dialog.dart';
import 'package:easthardware_pms/presentation/views/billing/components/print_invoice.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:easthardware_pms/utils/user.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataRow, DataTableSource;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class InvoiceDataSource extends DataTableSource {
  InvoiceDataSource({
    required this.invoices,
    required this.context,
  });

  final List<Invoice> invoices;
  final BuildContext context;

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
    final accessLevel = context.watchAccessLevel();

    return DataRowMapper.mapInvoiceToRow(
      invoice,
      viewAction: () {
        unawaited(
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (context) => InvoiceInformationContentDialog(invoice: invoice),
          ),
        );
      },
      editAction: () {
        if (accessLevel == AccessLevel.administrator) {
          return () => context.navigateWithExtra(AppRoutes.admin.editInvoice, invoice);
        } else {
          return () => context.navigateWithExtra(AppRoutes.staff.editInvoice, invoice);
        }
      }(),
      printAction: () {
        final allCategories = context.read<CategoryListBloc>().state.categories;
        final allProducts = context.read<ProductListBloc>().state.allProducts;
        final invoiceProducts = (context.read<InvoiceListBloc>().state.invoiceProducts)
            .where((p) => p.invoiceId == invoice.id)
            .toList();

        generateInvoicePdf(invoice, invoiceProducts, allProducts, allCategories);
      },
      receivePaymentAction: () {
        if (accessLevel == AccessLevel.administrator) {
          return () =>
              context.navigateWithExtra(AppRoutes.admin.createPayment.withInvoice, invoice);
        } else {
          return () =>
              context.navigateWithExtra(AppRoutes.staff.createPayment.withInvoice, invoice);
        }
      }(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => invoices.length;

  @override
  int get selectedRowCount => 0;
}
