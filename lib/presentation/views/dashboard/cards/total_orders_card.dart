import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TotalOrdersCard extends StatelessWidget {
  const TotalOrdersCard({super.key});

  @override
  Widget build(BuildContext context) {
    final totalOrders = context.select(
      (OrderListBloc b) => b.state.allOrders.length,
    );

    return KPICard(
      'Total Orders',
      value: '$totalOrders orders',
      icon: const Icon(FluentIcons.shopping_cart),
    );
  }
}
