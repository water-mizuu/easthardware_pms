import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/navigation/navigation_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart'
    show
        CardTheme,
        DataColumn,
        DataRow,
        DataTableSource,
        DataTableThemeData,
        PaginatedDataTable,
        Theme,
        ThemeData;
import 'package:flutter_bloc/flutter_bloc.dart';

class InvoicePanePage extends StatelessWidget {
  const InvoicePanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: Column(
        children: const [
          PageHeader(),
          PageActions(),
          InvoiceDataTable(),
        ].withSpacing(() => Spacing.v12),
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
        const HeadingText('Billing'),
        const Spacer(flex: 1),
        TextButtonFilled(
          "Create Invoice",
          onPressed: () => context //
              .read<NavigationCubit>()
              .navigateTo(AppRoutes.admin.createInvoice),
        ),
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
        Expanded(child: TextFormBox(placeholder: "Search", onChanged: (value) {})),
        const Spacer(flex: 2)
      ].withSpacing(() => Spacing.h12),
    );
  }
}

class InvoiceDataTable extends StatelessWidget {
  const InvoiceDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceListBloc, InvoiceListState>(
      builder: (context, state) {
        if (state.status == DataStatus.loading) {
          return const Center(child: ProgressRing());
        }
        final invoices = state.allInvoices;
        return Theme(
          data: ThemeData(
            dataTableTheme: const DataTableThemeData(
              dividerThickness: 0,
            ),
            cardTheme: const CardTheme(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
              color: Colors.white,
              elevation: 0,
            ),
          ),
          child: FractionallySizedBox(
            widthFactor: 1,
            child: PaginatedDataTable(
                headingRowHeight: 36,
                columnSpacing: 12,
                columns: const [
                  DataColumn(label: Text('Invoice Date')),
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Actions')),
                ],
                source: InvoiceDataSource(invoices)),
          ),
        );
      },
    );
  }
}

class InvoiceDataSource extends DataTableSource {
  InvoiceDataSource(this._invoices);
  final List<Invoice> _invoices;

  @override
  DataRow? getRow(int index) {
    if (index >= _invoices.length) return null;
    final invoice = _invoices[index];
    return DataRowMapper.mapInvoiceToRow(invoice, () {});
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _invoices.length;

  @override
  int get selectedRowCount => 0;
}
