import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/presentation/bloc/order/expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/order/expense_type_form_cubit.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, DataTable;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ManageExpenseTypePage extends StatelessWidget {
  const ManageExpenseTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          PageHeader(),
          PageTable(),
        ].withSpacing(() => Spacing.v16),
      ),
    );
  }
}

class PageTable extends StatelessWidget {
  const PageTable({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderListBloc, OrderListState>(
      builder: (context, orderState) {
        final orders = orderState.allOrders;
        final expenseTypeOrderMap = <int, int>{};

        // Count orders for each expense type
        for (final order in orders) {
          expenseTypeOrderMap.update(order.expenseType, (count) => count + 1, ifAbsent: () => 1);
        }

        return BlocBuilder<ExpenseTypeListBloc, ExpenseTypeListState>(
          builder: (context, state) {
            final expenseTypes = context.read<ExpenseTypeListBloc>().state.expenseTypes;

            return Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AnimatedSingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text("Expense Type Name")),
                      DataColumn(label: Text("Orders")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: expenseTypes
                        .map(
                          (expenseType) => DataRowMapper.mapExpenseTypeToRow(
                            expenseType,
                            expenseTypeOrderMap[expenseType.id] ?? 0,
                            // Only allow editing if it's not an inventory restock type (assuming id 1 is inventory restock)
                            // You may need to adjust this condition based on your actual data structure
                            expenseType.id == 1
                                ? null
                                : () {
                                    unawaited(showContentDialog(context, expenseType));
                                  },
                          ),
                        )
                        .toList(),
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

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const DisplayText('Manage Expense Types'),
        const Spacer(flex: 2),
        const PageActions(),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class PageActions extends StatelessWidget {
  const PageActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButtonFilled('Add Expense Type', onPressed: () async => showContentDialog(context))
      ].withSpacing(() => Spacing.h8),
    );
  }
}

Future<void> showContentDialog(BuildContext context, [ExpenseType? expenseType]) async {
  // Prevent editing of system expense types (inventory restock type)
  if (expenseType != null && expenseType.id == 1) {
    await showSingleDialog(
      (context) => ContentDialog(
        title: const Text('System Expense Type'),
        content: const Text('System expense types cannot be modified.'),
        actions: [
          Button(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
    return;
  }

  await showSingleDialog(
    (context) {
      final bloc = context.read<ExpenseTypeListBloc>();
      final existingNames = bloc.state.expenseTypes.map((expenseType) => expenseType.name).toList();
      final isAdding = expenseType == null;
      return BlocProvider(
        create: (context) => ExpenseTypeFormCubit(),
        child: Builder(builder: (context) {
          final formKey = context.read<ExpenseTypeFormCubit>().formKey;
          return BlocListener<ExpenseTypeFormCubit, ExpenseTypeFormState>(
            listenWhen: (previous, current) => previous.status != current.status,
            listener: (context, state) {
              if (state.status == FormStatus.submitting) {
                if (isAdding) {
                  bloc.add(AddExpenseTypeEvent(ExpenseType(name: state.name)));
                } else {
                  bloc.add(UpdateExpenseTypeEvent(expenseType.copyWith(name: state.name)));
                }
                context.read<ExpenseTypeFormCubit>().onSubmit();
              } else if (state.status == FormStatus.submitted) {
                if (context.mounted) {
                  context.pop();
                  context.read<ExpenseTypeFormCubit>().onFormReset();
                }
              }
            },
            child: ContentDialog(
              title: SubheadingText(
                  isAdding ? 'Create a new Expense Type' : 'Edit ${expenseType.name}'),
              content: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BodyText('Name'),
                    BlocBuilder<ExpenseTypeFormCubit, ExpenseTypeFormState>(
                      buildWhen: (previous, current) =>
                          previous.name != current.name ||
                          previous.errorMessage != current.errorMessage ||
                          previous.status != current.status,
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormBox(
                              initialValue: isAdding ? '' : expenseType.name,
                              onChanged: context.read<ExpenseTypeFormCubit>().onNameChanged,
                            ),
                            if (state.errorMessage != null && state.status == FormStatus.error)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  state.errorMessage!,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ].withSpacing(() => Spacing.v12),
                ),
              ),
              actions: [
                TextButton('Cancel', onPressed: context.pop),
                TextButtonFilled(
                  'Save Expense Type',
                  onPressed: () => context.read<ExpenseTypeFormCubit>().onButtonPressed(
                        existingNames: existingNames,
                        isAdding: isAdding,
                        currentName: isAdding ? null : expenseType.name,
                      ),
                )
              ],
            ),
          );
        }),
      );
    },
  );
}
