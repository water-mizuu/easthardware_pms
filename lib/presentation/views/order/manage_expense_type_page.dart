import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/presentation/bloc/order/expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/order/expense_type_display/display_expense_type.dart';
import 'package:easthardware_pms/presentation/cubit/order/expense_type_display/expense_type_display_cubit.dart';
import 'package:easthardware_pms/presentation/cubit/order/expense_type_display/expense_type_display_enum.dart';
import 'package:easthardware_pms/presentation/cubit/order/expense_type_form_cubit.dart';
import 'package:easthardware_pms/presentation/views/order/expense_type_data_source.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/table_theme_data.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/show_single_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show DataColumn, PaginatedDataTable;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scroll_animator/scroll_animator.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/notifications/cubit/notification_cubit.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';

class ManageExpenseTypePage extends StatefulWidget {
  const ManageExpenseTypePage({super.key});

  @override
  State<ManageExpenseTypePage> createState() => _ManageExpenseTypePageState();
}

class _ManageExpenseTypePageState extends State<ManageExpenseTypePage> {
  late final AnimatedScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimatedScrollController(animationFactory: const ChromiumEaseInOut());

    // Initial loading of expense types with order counts
    final orders = context.read<OrderListBloc>().state.allOrders;
    final expenseTypes = context.read<ExpenseTypeListBloc>().state.expenseTypes;

    // Count orders for each expense type
    final expenseTypeOrderMap = <int, int>{};
    for (final order in orders) {
      expenseTypeOrderMap.update(order.expenseType, (count) => count + 1, ifAbsent: () => 1);
    }

    // Create display expense types with order counts
    final displayExpenseTypes = expenseTypes
        .map((expenseType) => DisplayExpenseType.fromExpenseType(
              expenseType,
              orderCount: expenseTypeOrderMap[expenseType.id] ?? 0,
            ))
        .toList();

    // Update the display cubit
    context.read<ExpenseTypeDisplayCubit>().updateExpenseTypes(displayExpenseTypes);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseTypeListBloc, ExpenseTypeListState>(
      listenWhen: (prev, curr) => prev.expenseTypes != curr.expenseTypes,
      listener: (context, state) {
        // When expense types change, update the display with order counts
        final orders = context.read<OrderListBloc>().state.allOrders;
        final expenseTypeOrderMap = <int, int>{};
        for (final order in orders) {
          expenseTypeOrderMap.update(order.expenseType, (count) => count + 1, ifAbsent: () => 1);
        }

        final displayExpenseTypes = state.expenseTypes
            .map((expenseType) => DisplayExpenseType.fromExpenseType(
                  expenseType,
                  orderCount: expenseTypeOrderMap[expenseType.id] ?? 0,
                ))
            .toList();

        context.read<ExpenseTypeDisplayCubit>().updateExpenseTypes(displayExpenseTypes);
      },
      child: Padding(
        padding: AppPadding.panePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(),
            Spacing.v16,
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SearchRow(),
                    Spacing.v16,
                    ExpenseTypesDataTable(),
                  ],
                ),
              ),
            ),
          ],
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
        const DisplayText('Manage Expense Types'),
        const Spacer(flex: 2),
        TextButtonFilled('Add Expense Type', onPressed: () async => showContentDialog(context)),
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class SearchRow extends StatelessWidget {
  const SearchRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(
            child: TextBox(
              placeholder: 'Search expense type',
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              onChanged: (value) {
                context.read<ExpenseTypeDisplayCubit>().updateSearch(value);
              },
            ),
          ),
          const SizedBox(width: 48),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class ExpenseTypesDataTable extends StatelessWidget {
  const ExpenseTypesDataTable({super.key});

  int? _getSortColumnIndex(ExpenseTypeDisplaySortBy sortBy) {
    switch (sortBy) {
      case ExpenseTypeDisplaySortBy.idAscending:
      case ExpenseTypeDisplaySortBy.idDescending:
        return 0; // Index of the ID column
      case ExpenseTypeDisplaySortBy.nameAscending:
      case ExpenseTypeDisplaySortBy.nameDescending:
        return 1; // Index of the Name column
      case ExpenseTypeDisplaySortBy.ordersAscending:
      case ExpenseTypeDisplaySortBy.ordersDescending:
        return 2; // Index of the Orders column
      default:
        return null; // No column is being sorted
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseTypeDisplayCubit, ExpenseTypeDisplayState>(
      builder: (context, state) {
        final expenseTypeDisplayCubit = context.read<ExpenseTypeDisplayCubit>();
        final filtered = state.filteredExpenseTypes;
        final allExpenseTypes = state.allExpenseTypes ?? [];

        return TableThemeData(
          child: PaginatedDataTable(
            showFirstLastButtons: true,
            showCheckboxColumn: false,
            horizontalMargin: 20,
            columnSpacing: 16,
            sortColumnIndex: _getSortColumnIndex(state.sortBy),
            sortAscending: state.sortAscending,
            checkboxHorizontalMargin: 0,
            columns: [
              DataColumn(
                label: Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        const Text('ID'),
                        if (_getSortColumnIndex(state.sortBy) != 0) ...[
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
                  // Toggle between ascending and descending based on current sort type
                  if (state.sortBy == ExpenseTypeDisplaySortBy.idAscending) {
                    expenseTypeDisplayCubit.updateSort(ExpenseTypeDisplaySortBy.idDescending);
                  } else {
                    expenseTypeDisplayCubit.updateSort(ExpenseTypeDisplaySortBy.idAscending);
                  }
                },
              ),
              DataColumn(
                label: Expanded(
                  child: Row(
                    children: [
                      const Text('Expense Type Name'),
                      if (_getSortColumnIndex(state.sortBy) != 1) ...[
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
                  // Toggle between ascending and descending based on current sort type
                  if (state.sortBy == ExpenseTypeDisplaySortBy.nameAscending) {
                    expenseTypeDisplayCubit.updateSort(ExpenseTypeDisplaySortBy.nameDescending);
                  } else {
                    expenseTypeDisplayCubit.updateSort(ExpenseTypeDisplaySortBy.nameAscending);
                  }
                },
              ),
              DataColumn(
                label: Expanded(
                  child: Row(
                    children: [
                      const Text('Orders'),
                      const Spacer(),
                      if (_getSortColumnIndex(state.sortBy) != 2) ...[
                        const Spacer(),
                        const Icon(
                          FluentIcons.scroll_up_down,
                          size: 12,
                        ),
                      ]
                    ],
                  ),
                ),
                onSort: (_, __) {
                  // Toggle between ascending and descending based on current sort type
                  if (state.sortBy == ExpenseTypeDisplaySortBy.ordersAscending) {
                    expenseTypeDisplayCubit.updateSort(ExpenseTypeDisplaySortBy.ordersDescending);
                  } else {
                    expenseTypeDisplayCubit.updateSort(ExpenseTypeDisplaySortBy.ordersAscending);
                  }
                },
              ),
              const DataColumn(
                label: Expanded(
                  child: Text('Action'),
                ),
              ),
            ],
            source: ExpenseTypeDataSource(
              context: context,
              expenseTypes: filtered ?? allExpenseTypes,
              onEdit: (displayExpenseType) {
                unawaited(showContentDialog(context, displayExpenseType.expenseType));
              },
            ),
          ),
        );
      },
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
    barrierDismissible: true,
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
                final authState = context.read<AuthenticationBloc>().state;
                if (isAdding) {
                  bloc.add(AddExpenseTypeEvent(ExpenseType(name: state.name)));
                  context.read<UserLogListBloc>().add(
                        AddUpdateEvent(
                          'Expense Type #${bloc.state.expenseTypes.length + 1}',
                          authState.user!,
                        ),
                      );
                } else {
                  bloc.add(UpdateExpenseTypeEvent(expenseType.copyWith(name: state.name)));
                  context.read<UserLogListBloc>().add(
                        AddUpdateEvent(
                          'Expense Type #${expenseType.id}',
                          authState.user!,
                        ),
                      );
                  context.read<NotificationCubit>().addNotification(
                        type: NotificationType.warning,
                        title: 'Notice:',
                        message:
                            '${expenseType.name} expense type was updated by ${authState.user!.username}.',
                        path: '',
                      );
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
              title: Text(
                isAdding ? 'Create a new Expense Type' : 'Edit ${expenseType.name}',
                style: TextStyles.title,
              ),
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
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(30),
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^[a-zA-Z0-9\s\-_]+$'),
                                  replacementString: context //
                                      .select((ExpenseTypeFormCubit b) => b.state.name),
                                ),
                              ],
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
