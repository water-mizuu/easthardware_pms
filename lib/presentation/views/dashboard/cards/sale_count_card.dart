import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class LowStockCountCard extends StatelessWidget {
  const LowStockCountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.select((ProductListBloc b) => b.state.allProducts);
    final lowStockProducts = products.where((p) => (p.isBelowReorderPoint ?? false)).length;

    return KPICard(
      'Low Stock Products',
      value: lowStockProducts.toString(),
      icon: const Icon(FluentIcons.product),
    );
  }
}
