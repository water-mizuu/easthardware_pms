import 'package:easthardware_pms/domain/enums/enums.dart';
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
    return Row(
      children: [
        const Text(
          'Payments',
          style: TextStyles.display,
        ),
        const Spacer(),
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
    return BlocBuilder<PaymentDisplayCubit, PaymentDisplayState>(
      builder: (context, methodState) {
        return BlocBuilder<PaymentListBloc, PaymentListState>(
          builder: (context, state) {
            final paymentBloc = context.read<PaymentDisplayCubit>();
            final payments = paymentBloc.state.allPayments;
            final paymentMethodBloc = context.read<PaymentMethodListBloc>();
            final paymentMethods = paymentMethodBloc.state.paymentMethods;

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
                          sortAscending: paymentBloc.state.sortAscending,
                          sortColumnIndex: _getSortColumnIndex(paymentBloc.state.sortBy),
                          columns: [
                            DataColumn(
                              label: const Expanded(
                                child: Text('Date', style: TextStyles.tableHeader),
                              ),
                              onSort: (_, __) {
                                context.read<PaymentDisplayCubit>().sort(
                                      paymentBloc.state.sortBy == PaymentDisplaySortBy.dateAscending
                                          ? PaymentDisplaySortBy.dateDescending
                                          : PaymentDisplaySortBy.dateAscending,
                                    );
                              },
                            ),
                            DataColumn(
                              label: const Expanded(
                                child: Text('Amount', style: TextStyles.tableHeader),
                              ),
                              onSort: (_, __) {
                                context.read<PaymentDisplayCubit>().sort(
                                      paymentBloc.state.sortBy ==
                                              PaymentDisplaySortBy.amountAscending
                                          ? PaymentDisplaySortBy.amountDescending
                                          : PaymentDisplaySortBy.amountAscending,
                                    );
                              },
                            ),
                            DataColumn(
                              label: const Expanded(
                                child: Text('Reference', style: TextStyles.tableHeader),
                              ),
                              onSort: (_, __) {
                                context.read<PaymentDisplayCubit>().sort(
                                      paymentBloc.state.sortBy ==
                                              PaymentDisplaySortBy.referenceAscending
                                          ? PaymentDisplaySortBy.referenceDescending
                                          : PaymentDisplaySortBy.referenceAscending,
                                    );
                              },
                            ),
                            const DataColumn(
                              label: Expanded(
                                child: Text('Payment Method', style: TextStyles.tableHeader),
                              ),
                            ),
                            const DataColumn(
                              label: Expanded(
                                child: Text('Actions', style: TextStyles.tableHeader),
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
