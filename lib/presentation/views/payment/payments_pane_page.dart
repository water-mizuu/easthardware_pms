import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_list/payment_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_method_list/'
    'payment_method_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/payment/payment_display/'
    'payment_display_cubit.dart';
import 'package:easthardware_pms/presentation/views/payment/components/payment_data_source.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/table_theme_data.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
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
    // Get payments from the payment bloc
    context.read<PaymentDisplayCubit>().updatePayments(
          context.read<PaymentListBloc>().state.payments,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentListBloc, PaymentListState>(
      listenWhen: (previous, current) => previous.payments != current.payments,
      listener: (context, state) {
        context.read<PaymentDisplayCubit>().updatePayments(state.payments);
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
    return const Row(
      children: [
        Text(
          'Payments',
          style: TextStyles.display,
        ),
        Spacer(),
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
            const Spacer(flex: 2),
            TextButtonFilled(
              'Add Payment',
              onPressed: () {
                // Show payment form dialog
              },
            ),
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
      case PaymentDisplaySortBy.amountAscending:
      case PaymentDisplaySortBy.amountDescending:
        return 1; // Index of the Amount column
      case PaymentDisplaySortBy.referenceAscending:
      case PaymentDisplaySortBy.referenceDescending:
        return 2; // Index of the Reference column
      default:
        return null; // No column is being sorted
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentMethodListBloc, PaymentMethodListState>(
      builder: (context, methodState) {
        return BlocBuilder<PaymentDisplayCubit, PaymentDisplayState>(
          builder: (context, state) {
            final payments = state.filteredPayments ?? state.allPayments;

            return Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).acrylicBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: payments == null || payments.isEmpty
                    ? const Center(
                        child: Text('No payments found', style: TextStyles.body),
                      )
                    : TableThemeData(
                        child: PaginatedDataTable(
                          source: PaymentDataSource(
                            payments: payments,
                            paymentMethods: methodState.paymentMethods,
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
                          sortAscending: state.sortAscending,
                          sortColumnIndex: _getSortColumnIndex(state.sortBy),
                          columns: [
                            DataColumn(
                              label: const Text('Date', style: TextStyles.tableHeader),
                              onSort: (_, __) {
                                context.read<PaymentDisplayCubit>().sort(
                                      state.sortBy == PaymentDisplaySortBy.dateAscending
                                          ? PaymentDisplaySortBy.dateDescending
                                          : PaymentDisplaySortBy.dateAscending,
                                    );
                              },
                            ),
                            DataColumn(
                              label: const Text('Amount', style: TextStyles.tableHeader),
                              onSort: (_, __) {
                                context.read<PaymentDisplayCubit>().sort(
                                      state.sortBy == PaymentDisplaySortBy.amountAscending
                                          ? PaymentDisplaySortBy.amountDescending
                                          : PaymentDisplaySortBy.amountAscending,
                                    );
                              },
                            ),
                            DataColumn(
                              label: const Text('Reference', style: TextStyles.tableHeader),
                              onSort: (_, __) {
                                context.read<PaymentDisplayCubit>().sort(
                                      state.sortBy == PaymentDisplaySortBy.referenceAscending
                                          ? PaymentDisplaySortBy.referenceDescending
                                          : PaymentDisplaySortBy.referenceAscending,
                                    );
                              },
                            ),
                            const DataColumn(
                              label: Text('Payment Method', style: TextStyles.tableHeader),
                            ),
                            const DataColumn(
                              label: Text('Actions', style: TextStyles.tableHeader),
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
