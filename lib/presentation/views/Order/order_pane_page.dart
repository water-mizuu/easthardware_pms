import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/helper/data_row_mapper.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/data_table_place_holder.dart';
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

class OrderPanePage extends StatelessWidget {
  const OrderPanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(),
          Spacing.v4,
          const PageActions(),
          const OrdersDataTable(),
        ].withSpacing(() => Spacing.v16),
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
          "Create Order",
          onPressed: () {},
        ),
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
        const Expanded(child: TextBox(placeholder: "Search")),
        const Spacer(flex: 2),
      ].withSpacing(() => Spacing.h12),
    );
  }
}

class OrdersDataTable extends StatelessWidget {
  const OrdersDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderListBloc, OrderListState>(
      builder: (context, state) {
        if (state.status == DataStatus.loading) {
          return const Center(child: ProgressRing());
        }

        final orders = state.allOrders;
        if (orders.isEmpty) {
          return const DataTablePlaceHolder(FluentIcons.product_list, 'Orders');
        }

        return Theme(
          data: ThemeData(
            dataTableTheme: const DataTableThemeData(
              dividerThickness: 0,
            ),
            cardTheme: const CardTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
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
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Order Date')),
                DataColumn(label: Text('Payee')),
                DataColumn(label: Text('Expense Type')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Actions')),
              ],
              source: OrderDataSource(orders),
            ),
          ),
        );
      },
    );
  }
}

class OrderDataSource extends DataTableSource {
  OrderDataSource(this._orders);
  final List<Order> _orders;

  @override
  DataRow? getRow(int index) {
    if (index >= _orders.length) return null;
    final order = _orders[index];
    return DataRowMapper.mapOrderToRow(order, () {
      // Implement your edit or action logic here
    });
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _orders.length;

  @override
  int get selectedRowCount => 0;
}
