import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/billing/'
    'invoice_display/invoice_display_cubit.dart';
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
    context
        .read<InvoiceDisplayCubit>()
        .updateInvoices(context.read<InvoiceListBloc>().state.invoices);
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
                placeholder: 'Search',
                onChanged: (e) => context.read<InvoiceDisplayCubit>().search(e),
              ),
            ),
            const SizedBox(width: 48),
            const Spacer(flex: 2),
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
        return 0;
      case InvoiceDisplaySortBy.numberAscending:
      case InvoiceDisplaySortBy.numberDescending:
        return 1;
      case InvoiceDisplaySortBy.customerAscending:
      case InvoiceDisplaySortBy.customerDescending:
        return 2;
      case InvoiceDisplaySortBy.totalAscending:
      case InvoiceDisplaySortBy.totalDescending:
        return 3;
      case InvoiceDisplaySortBy.statusAscending:
      case InvoiceDisplaySortBy.statusDescending:
        return 4;
      default:
        return null;
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

            final displayCubit = context.read<InvoiceDisplayCubit>();
            final invoices = displayCubit.state.filteredInvoices ?? displayCubit.state.allInvoices;

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

            return Flexible(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).acrylicBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TableThemeData(
                  child: PaginatedDataTable(
                    key: ValueKey(context.watch<InvoiceDisplayCubit>().state.sortAscending),
                    showCheckboxColumn: false,
                    columnSpacing: 16.0,
                    header: null,
                    rowsPerPage: 10,
                    sortColumnIndex: _getSortColumnIndex(displayState.sortBy),
                    sortAscending: context.watch<InvoiceDisplayCubit>().state.sortAscending,
                    columns: [
                      DataColumn(
                        label: Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 75),
                            child: Row(
                              children: [
                                const Text('Date', style: TextStyles.tableHeader),
                                if (_getSortColumnIndex(displayState.sortBy) != 0) ...[
                                  const Spacer(),
                                  const Icon(
                                    FluentIcons.scroll_up_down,
                                    size: 12,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        onSort: (_, __) {
                          if (displayState.sortBy == InvoiceDisplaySortBy.invoiceDateAscending ||
                              displayState.sortBy == InvoiceDisplaySortBy.invoiceDateDescending) {
                            displayCubit.sort(displayState.sortBy);
                          } else {
                            displayCubit.sort(InvoiceDisplaySortBy.invoiceDateAscending);
                          }
                        },
                      ),
                      DataColumn(
                        label: Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 75),
                            child: Row(
                              children: [
                                const Text('Invoice No.', style: TextStyles.tableHeader),
                                if (_getSortColumnIndex(displayState.sortBy) != 1) ...[
                                  const Spacer(),
                                  const Icon(
                                    FluentIcons.scroll_up_down,
                                    size: 12,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        onSort: (_, __) {
                          if (displayState.sortBy == InvoiceDisplaySortBy.numberAscending ||
                              displayState.sortBy == InvoiceDisplaySortBy.numberDescending) {
                            displayCubit.sort(displayState.sortBy);
                          } else {
                            displayCubit.sort(InvoiceDisplaySortBy.numberAscending);
                          }
                        },
                      ),
                      DataColumn(
                        label: Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Row(
                              children: [
                                const Text('Customer', style: TextStyles.tableHeader),
                                if (_getSortColumnIndex(displayState.sortBy) != 2) ...[
                                  const Spacer(),
                                  const Icon(
                                    FluentIcons.scroll_up_down,
                                    size: 12,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        onSort: (_, __) {
                          if (displayState.sortBy == InvoiceDisplaySortBy.customerAscending ||
                              displayState.sortBy == InvoiceDisplaySortBy.customerDescending) {
                            displayCubit.sort(displayState.sortBy);
                          } else {
                            displayCubit.sort(InvoiceDisplaySortBy.customerAscending);
                          }
                        },
                      ),
                      DataColumn(
                        label: Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 75),
                            child: Row(
                              children: [
                                const Text('Total', style: TextStyles.tableHeader),
                                if (_getSortColumnIndex(displayState.sortBy) != 3) ...[
                                  const Spacer(),
                                  const Icon(
                                    FluentIcons.scroll_up_down,
                                    size: 12,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        onSort: (_, __) {
                          if (displayState.sortBy == InvoiceDisplaySortBy.totalAscending ||
                              displayState.sortBy == InvoiceDisplaySortBy.totalDescending) {
                            displayCubit.sort(displayState.sortBy);
                          } else {
                            displayCubit.sort(InvoiceDisplaySortBy.totalAscending);
                          }
                        },
                      ),
                      DataColumn(
                        label: Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 75),
                            child: Row(
                              children: [
                                const Text('Status', style: TextStyles.tableHeader),
                                if (_getSortColumnIndex(displayState.sortBy) != 4) ...[
                                  const Spacer(),
                                  const Icon(
                                    FluentIcons.scroll_up_down,
                                    size: 12,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        onSort: (_, __) {
                          if (displayState.sortBy == InvoiceDisplaySortBy.statusAscending ||
                              displayState.sortBy == InvoiceDisplaySortBy.statusDescending) {
                            displayCubit.sort(displayState.sortBy);
                          } else {
                            displayCubit.sort(InvoiceDisplaySortBy.statusAscending);
                          }
                        },
                      ),
                      const DataColumn(
                        label: Expanded(child: Text('')),
                      ),
                    ],
                    source: InvoiceDataSource(
                      invoices: invoices,
                      context: context,
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
