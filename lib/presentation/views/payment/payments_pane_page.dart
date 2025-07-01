import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_list/payment_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_method_list/'
    'payment_method_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/payment/payment_display/'
    'payment_display_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/payment/components/payment_data_source.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/table_theme_data.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, PaginatedDataTable;
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentsPanePage extends StatefulWidget {
  const PaymentsPanePage({super.key});

  @override
  State<PaymentsPanePage> createState() => _PaymentsPanePageState();
}

class _PaymentsPanePageState extends State<PaymentsPanePage> {
  @override
  void initState() {
    super.initState();
    final invoices = context.read<InvoiceListBloc>().state.invoices;
    // Get payments from the payment bloc
    final payments = context.read<PaymentListBloc>().state.payments;
    context.read<PaymentDisplayCubit>().updatePayments(payments.map((payment) {
          final invoice = invoices.firstWhere((invoice) => invoice.id == payment.invoiceId);
          return (payment, invoice.customerName);
        }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentListBloc, PaymentListState>(
      listenWhen: (previous, current) => previous.payments != current.payments,
      listener: (context, state) {
        final invoices = context.read<InvoiceListBloc>().state.invoices;
        final payments = state.payments.map((payment) {
          final invoice = invoices.firstWhere((invoice) => invoice.id == payment.invoiceId);
          return (payment, invoice.customerName);
        }).toList();
        context.read<PaymentDisplayCubit>().updatePayments(payments);
      },
      child: Padding(
        padding: AppPadding.panePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(),
            const PageActions(),
            const PaymentsDataTable(),
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
        const Text(
          'Payments',
          style: TextStyles.display,
        ),
        const Spacer(),
        TextButton(
          'Manage Payment Methods',
          onPressed: () {
            context.navigate(AppRoutes.admin.managePaymentMethods);
          },
        ),
        const SizedBox(width: 8),
        TextButtonFilled(
          'Add Payment',
          onPressed: () {
            context.navigate(AppRoutes.admin.createPayment.withoutInvoice);
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
        const Text('List of Payments', style: TextStyles.subtitle),
        Spacing.v12,
        Row(
          children: [
            Expanded(
              child: TextBox(
                placeholder: 'Search by reference number or amount',
                onChanged: (value) => context.read<PaymentDisplayCubit>().search(value),
              ),
            ),
            const Spacer(flex: 2)
          ].withSpacing(() => Spacing.h8),
        ),
      ],
    );
  }
}

class PaymentsDataTable extends StatelessWidget {
  const PaymentsDataTable({super.key});

  int? _getSortColumnIndex(PaymentDisplaySortBy sortBy) {
    switch (sortBy) {
      case PaymentDisplaySortBy.dateAscending:
      case PaymentDisplaySortBy.dateDescending:
        return 0; // Index of the Date column
      case PaymentDisplaySortBy.customerAscending:
      case PaymentDisplaySortBy.customerDescending:
        return 1; // Index of the Amount column
      case PaymentDisplaySortBy.referenceAscending:
      case PaymentDisplaySortBy.referenceDescending:
        return 2; // Index of the Reference column
      case PaymentDisplaySortBy.amountAscending:
      case PaymentDisplaySortBy.amountDescending:
        return 3; // Index of the Reference column
      default:
        return null; // No column is being sorted
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentDisplayCubit, PaymentDisplayState>(
      builder: (context, displayState) {
        return BlocBuilder<PaymentListBloc, PaymentListState>(
          builder: (context, state) {
            final displayCubit = context.read<PaymentDisplayCubit>();
            final paymentMethodBloc = context.read<PaymentMethodListBloc>();
            final paymentMethods = paymentMethodBloc.state.paymentMethods;

            final payments = displayState.filteredPayments ?? displayState.allPayments ?? [];
            return Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: payments.isEmpty
                    ? const Center(
                        child: Text('No payments found', style: TextStyles.body),
                      )
                    : TableThemeData(
                        child: PaginatedDataTable(
                          source: PaymentDataSource(
                            payments: payments,
                            paymentMethods: paymentMethods,
                            context: context,
                            onEdit: (payment) {
                              // Handle edit payment
                            },
                            onDelete: (payment) {
                              // Handle delete payment
                            },
                          ),
                          header: null,
                          rowsPerPage: 10,
                          columnSpacing: 50,
                          showCheckboxColumn: false,
                          sortAscending: displayCubit.state.sortAscending,
                          sortColumnIndex: _getSortColumnIndex(displayCubit.state.sortBy),
                          columns: [
                            DataColumn(
                              label: Expanded(
                                child: Row(
                                  children: [
                                    const Text('Date', style: TextStyles.tableHeader),
                                    if (_getSortColumnIndex(displayCubit.state.sortBy) != 0) ...[
                                      const Spacer(),
                                      const Icon(
                                        FluentIcons.scroll_up_down,
                                        size: 12,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              onSort: (_, __) {
                                if (displayState.sortBy == PaymentDisplaySortBy.dateAscending ||
                                    displayState.sortBy == PaymentDisplaySortBy.dateDescending) {
                                  displayCubit.sort(displayState.sortBy);
                                } else {
                                  displayCubit.sort(PaymentDisplaySortBy.dateAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Row(
                                  children: [
                                    const Text('Customer', style: TextStyles.tableHeader),
                                    if (_getSortColumnIndex(displayCubit.state.sortBy) != 1) ...[
                                      const Spacer(),
                                      const Icon(
                                        FluentIcons.scroll_up_down,
                                        size: 12,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              onSort: (_, __) {
                                if (displayState.sortBy == PaymentDisplaySortBy.customerAscending ||
                                    displayState.sortBy ==
                                        PaymentDisplaySortBy.customerDescending) {
                                  displayCubit.sort(displayState.sortBy);
                                } else {
                                  displayCubit.sort(PaymentDisplaySortBy.customerAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Row(
                                  children: [
                                    const Text('Payment Reference', style: TextStyles.tableHeader),
                                    if (_getSortColumnIndex(displayCubit.state.sortBy) != 2) ...[
                                      const Spacer(),
                                      const Icon(
                                        FluentIcons.scroll_up_down,
                                        size: 12,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              onSort: (_, __) {
                                if (displayState.sortBy ==
                                        PaymentDisplaySortBy.referenceAscending ||
                                    displayState.sortBy ==
                                        PaymentDisplaySortBy.referenceAscending) {
                                  displayCubit.sort(displayState.sortBy);
                                } else {
                                  displayCubit.sort(PaymentDisplaySortBy.referenceAscending);
                                }
                              },
                            ),
                            DataColumn(
                              label: Expanded(
                                child: Row(
                                  children: [
                                    const Text('Amount', style: TextStyles.tableHeader),
                                    if (_getSortColumnIndex(displayCubit.state.sortBy) != 3) ...[
                                      const Spacer(),
                                      const Icon(
                                        FluentIcons.scroll_up_down,
                                        size: 12,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              onSort: (_, __) {
                                if (displayState.sortBy == PaymentDisplaySortBy.amountAscending ||
                                    displayState.sortBy == PaymentDisplaySortBy.amountDescending) {
                                  displayCubit.sort(displayState.sortBy);
                                } else {
                                  displayCubit.sort(PaymentDisplaySortBy.amountAscending);
                                }
                              },
                            ),
                            const DataColumn(
                              label: Expanded(
                                child: Row(
                                  children: [
                                    Text('Payment Method', style: TextStyles.tableHeader),
                                  ],
                                ),
                              ),
                            ),
                            const DataColumn(
                              label: Expanded(
                                child: Row(
                                  children: [
                                    Text('Actions', style: TextStyles.tableHeader),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
