import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/presentation/bloc/order/expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/order/cubit/order_display_cubit.dart';
import 'package:easthardware_pms/presentation/cubit/order/cubit/order_display_enum.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/order/components/order_information_content_dialog.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/table_theme_data.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart'
    show DataColumn, DataRow, DataTableSource, PaginatedDataTable;
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderPanePage extends StatefulWidget {
  const OrderPanePage({super.key});

  @override
  State<OrderPanePage> createState() => _OrderPanePageState();
}

class _OrderPanePageState extends State<OrderPanePage> {
  @override
  void initState() {
    super.initState();
    // Get orders from the order list bloc
    context.read<OrderDisplayCubit>().updateOrders(
          context.read<OrderListBloc>().state.allOrders,
        );

    // Ensure expense type list is loaded
    final expenseTypeListBloc = context.read<ExpenseTypeListBloc>();
    if (expenseTypeListBloc.state.expenseTypes.isEmpty) {
      expenseTypeListBloc.add(FetchAllExpenseTypesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderListBloc, OrderListState>(
      listenWhen: (previous, current) => previous.allOrders != current.allOrders,
      listener: (context, state) {
        context.read<OrderDisplayCubit>().updateOrders(state.allOrders);
      },
      child: Padding(
        padding: AppPadding.panePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(),
            const PageActions(),
            const OrdersDataTable(),
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
        const HeadingText('Orders'),
        const Spacer(flex: 1),
        TextButtonFilled(
          "Create Restock Order",
          onPressed: () {
            context.navigate(AppRoutes.admin.createRestockOrder.withoutProduct);
          },
        ),
        TextButtonFilled(
          "Create Expense Order",
          onPressed: () {
            context.navigate(AppRoutes.admin.createExpenseOrder);
          },
        ),
      ].withSpacing(() => Spacing.h16),
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
        const Text('List of Orders', style: TextStyles.subtitle),
        Spacing.v12,
        Row(
          children: [
            Expanded(
              child: TextBox(
                placeholder: 'Search by ID, payee, or amount',
                onChanged: (value) => context.read<OrderDisplayCubit>().search(value),
              ),
            ),
            const Spacer(flex: 2)
          ].withSpacing(() => Spacing.h8),
        ),
      ],
    );
  }
}

class OrdersDataTable extends StatelessWidget {
  const OrdersDataTable({super.key});

  int? _getSortColumnIndex(OrderDisplaySortBy sortBy) {
    switch (sortBy) {
      case OrderDisplaySortBy.orderDateAscending:
      case OrderDisplaySortBy.orderDateDescending:
        return 1;
      case OrderDisplaySortBy.idAscending:
      case OrderDisplaySortBy.idDescending:
        return 0;
      case OrderDisplaySortBy.payeeNameAscending:
      case OrderDisplaySortBy.payeeNameDescending:
        return 2;
      case OrderDisplaySortBy.expenseTypeAscending:
      case OrderDisplaySortBy.expenseTypeDescending:
        return 3;
      case OrderDisplaySortBy.amountDueAscending:
      case OrderDisplaySortBy.amountDueDescending:
        return 4;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderDisplayCubit, OrderDisplayState>(
      builder: (context, displayState) {
        return BlocBuilder<OrderListBloc, OrderListState>(
          builder: (context, state) {
            if (state.status == DataStatus.loading) {
              return const Center(child: ProgressRing());
            }

            final displayCubit = context.read<OrderDisplayCubit>();
            final orders = displayCubit.state.filteredOrders ?? displayCubit.state.allOrders;

            if (orders == null || orders.isEmpty) {
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text('No orders found', style: TextStyles.body),
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
                    sortAscending: displayState.sortAscending,
                    columns: [
                      DataColumn(
                        label: Expanded(
                          child: Row(
                            children: [
                              const Text('Order Date', style: TextStyles.tableHeader),
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
                        onSort: (_, __) {
                          if (displayState.sortBy == OrderDisplaySortBy.orderDateAscending ||
                              displayState.sortBy == OrderDisplaySortBy.orderDateDescending) {
                            displayCubit.sort(displayState.sortBy);
                          } else {
                            displayCubit.sort(OrderDisplaySortBy.orderDateAscending);
                          }
                        },
                      ),
                      DataColumn(
                        label: Expanded(
                          child: Row(
                            children: [
                              const Text('ID', style: TextStyles.tableHeader),
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
                        onSort: (_, __) {
                          if (displayState.sortBy == OrderDisplaySortBy.idAscending ||
                              displayState.sortBy == OrderDisplaySortBy.idDescending) {
                            displayCubit.sort(displayState.sortBy);
                          } else {
                            displayCubit.sort(OrderDisplaySortBy.idAscending);
                          }
                        },
                      ),
                      DataColumn(
                        label: Expanded(
                          child: Row(
                            children: [
                              const Text('Payee', style: TextStyles.tableHeader),
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
                        onSort: (_, __) {
                          if (displayState.sortBy == OrderDisplaySortBy.payeeNameAscending ||
                              displayState.sortBy == OrderDisplaySortBy.payeeNameDescending) {
                            displayCubit.sort(displayState.sortBy);
                          } else {
                            displayCubit.sort(OrderDisplaySortBy.payeeNameAscending);
                          }
                        },
                      ),
                      DataColumn(
                        label: Expanded(
                          child: Row(
                            children: [
                              const Text('Expense Type', style: TextStyles.tableHeader),
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
                        onSort: (_, __) {
                          if (displayState.sortBy == OrderDisplaySortBy.expenseTypeAscending ||
                              displayState.sortBy == OrderDisplaySortBy.expenseTypeDescending) {
                            displayCubit.sort(displayState.sortBy);
                          } else {
                            displayCubit.sort(OrderDisplaySortBy.expenseTypeAscending);
                          }
                        },
                      ),
                      DataColumn(
                        label: Expanded(
                          child: Row(
                            children: [
                              const Text('Amount', style: TextStyles.tableHeader),
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
                        onSort: (_, __) {
                          if (displayState.sortBy == OrderDisplaySortBy.amountDueAscending ||
                              displayState.sortBy == OrderDisplaySortBy.amountDueDescending) {
                            displayCubit.sort(displayState.sortBy);
                          } else {
                            displayCubit.sort(OrderDisplaySortBy.amountDueAscending);
                          }
                        },
                      ),
                      const DataColumn(
                        label: Expanded(child: Text('Actions', style: TextStyles.tableHeader)),
                      ),
                    ],
                    source: OrderDataSource(orders, context),
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

class OrderDataSource extends DataTableSource {
  OrderDataSource(this._orders, this._context);
  final List<Order> _orders;
  final BuildContext _context;

  @override
  DataRow? getRow(int index) {
    if (index >= _orders.length) return null;
    final order = _orders[index];
    return DataRowMapper.mapOrderToRow(order, () {
      // Show order information dialog
      unawaited(showDialog(
        context: _context,
        builder: (context) => OrderInformationContentDialog(
          context: context,
          order: order,
        ),
      ));
    });
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _orders.length;

  @override
  int get selectedRowCount => 0;
}
