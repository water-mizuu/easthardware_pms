import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/billing/invoice_display/invoice_display_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/billing/components/invoice_data_source.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/table_theme_data.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, PaginatedDataTable;
import 'package:flutter_bloc/flutter_bloc.dart';

class InvoicePanePage extends StatefulWidget {
  const InvoicePanePage({super.key});

  @override
  State<InvoicePanePage> createState() => _InvoicePanePageState();
}

class _InvoicePanePageState extends State<InvoicePanePage> {
  @override
  void initState() {
    super.initState();
    // Get invoices from the invoice bloc
    context.read<InvoiceDisplayCubit>().updateInvoices(
          context.read<InvoiceListBloc>().state.invoices,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoiceListBloc, InvoiceListState>(
      listenWhen: (previous, current) => previous.invoices != current.invoices,
      listener: (context, state) {
        context.read<InvoiceDisplayCubit>().updateInvoices(state.invoices);
      },
      child: Padding(
        padding: AppPadding.panePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(),
            const PageActions(),
            const InvoiceDataTable(),
          ].withSpacing(() => Spacing.v16),
        ),
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
          onPressed: () {
            final user = context.read<AuthenticationBloc>().state.user;
            switch (user?.accessLevel) {
              case null:
                context.navigate(AppRoutes.login);
              case AccessLevel.staff:
                context.navigate(AppRoutes.staff.createInvoice);
              case AccessLevel.administrator:
                context.navigate(AppRoutes.admin.createInvoice);
            }
          },
        ),
      ],
    );
  }
}

class PageActions extends StatelessWidget {
  const PageActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('List of Invoices', style: TextStyles.subtitle),
        Spacing.v12,
        Row(
          children: [
            Expanded(
              child: TextBox(
                placeholder: 'Search by invoice number, customer, or amount',
                onChanged: (value) => context.read<InvoiceDisplayCubit>().search(value),
              ),
            ),
            const Spacer(flex: 2)
          ].withSpacing(() => Spacing.h8),
        ),
      ],
    );
  }
}

class InvoiceDataTable extends StatelessWidget {
  const InvoiceDataTable({super.key});

  int? _getSortColumnIndex(InvoiceDisplaySortBy sortBy) {
    switch (sortBy) {
      case InvoiceDisplaySortBy.invoiceDateAscending:
      case InvoiceDisplaySortBy.invoiceDateDescending:
        return 0; // Index of the Date column
      case InvoiceDisplaySortBy.numberAscending:
      case InvoiceDisplaySortBy.numberDescending:
        return 1; // Index of the Invoice Number column
      case InvoiceDisplaySortBy.customerAscending:
      case InvoiceDisplaySortBy.customerDescending:
        return 2; // Index of the Customer column
      case InvoiceDisplaySortBy.totalAscending:
      case InvoiceDisplaySortBy.totalDescending:
        return 3; // Index of the Amount column
      default:
        return null; // No column is being sorted
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceDisplayCubit, InvoiceDisplayState>(
      builder: (context, displayState) {
        return BlocBuilder<InvoiceListBloc, InvoiceListState>(
          builder: (context, state) {
            if (state.status == DataStatus.loading) {
              return const Center(child: ProgressRing());
            }

            final invoiceBloc = context.read<InvoiceDisplayCubit>();
            final invoices = invoiceBloc.state.filteredInvoices ?? invoiceBloc.state.allInvoices;

            if (invoices == null || invoices.isEmpty) {
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text('No invoices found', style: TextStyles.body),
                  ),
                ),
              );
            }

            return Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).acrylicBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TableThemeData(
                  child: PaginatedDataTable(
                    showCheckboxColumn: false,
                    columnSpacing: 16.0,
                    header: null,
                    rowsPerPage: 10,
                    sortColumnIndex: _getSortColumnIndex(displayState.sortBy),
                    sortAscending: context.watch<InvoiceDisplayCubit>().state.sortAscending,
                    columns: [
                      DataColumn(
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 75),
                          child: const Text('Date'),
                        ),
                        onSort: (_, __) => invoiceBloc.sort(
                          displayState.sortBy == InvoiceDisplaySortBy.invoiceDateAscending
                              ? InvoiceDisplaySortBy.invoiceDateDescending
                              : InvoiceDisplaySortBy.invoiceDateAscending,
                        ),
                      ),
                      DataColumn(
                        label: Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 75),
                            child: const Text('Invoice No.', style: TextStyles.tableHeader),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: const Text('Customer', style: TextStyles.tableHeader),
                          ),
                        ),
                        onSort: (_, __) => invoiceBloc.sort(
                          displayState.sortBy == InvoiceDisplaySortBy.customerAscending
                              ? InvoiceDisplaySortBy.customerDescending
                              : InvoiceDisplaySortBy.customerAscending,
                        ),
                      ),
                      DataColumn(
                        label: Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 75),
                            child: const Text('Total', style: TextStyles.tableHeader),
                          ),
                        ),
                        onSort: (_, __) => invoiceBloc.sort(
                          displayState.sortBy == InvoiceDisplaySortBy.totalAscending
                              ? InvoiceDisplaySortBy.totalDescending
                              : InvoiceDisplaySortBy.totalAscending,
                        ),
                      ),
                      DataColumn(
                        label: Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 75),
                            child: const Text('Status', style: TextStyles.tableHeader),
                          ),
                        ),
                        onSort: (_, __) => invoiceBloc.sort(
                          displayState.sortBy == InvoiceDisplaySortBy.totalAscending
                              ? InvoiceDisplaySortBy.totalDescending
                              : InvoiceDisplaySortBy.totalAscending,
                        ),
                      ),
                      const DataColumn(
                        label: Expanded(child: Text('')),
                      ),
                    ],
                    source: InvoiceDataSource(
                      invoices: invoices,
                      context: context,
                      onSort: invoiceBloc.sort,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
