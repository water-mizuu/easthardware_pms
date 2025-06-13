import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class ProductCountCard extends StatelessWidget {
  const ProductCountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final productCount = context.select((ProductListBloc b) => b.state.allProducts.length);

    return KPICard(
      'Product Count',
      value: productCount.toString(),
      icon: const Icon(FluentIcons.product),
    );
  }
}
