import 'package:easthardware_pms/presentation/views/dashboard/cards/product_count_card.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/sale_count_card.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/total_orders_card.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/total_sales_card.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';

class SummarySection extends StatelessWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutMode.builder((context, mode, keys) {
      final productCount = ProductCountCard(key: keys['productCount']);
      final saleCount = SaleCountCard(key: keys['saleCount']);
      final totalSales = TotalSalesCard(key: keys['totalSales']);
      final totalOrders = TotalOrdersCard(key: keys['totalOrders']);

      return switch (mode) {
        LayoutMode.wide => Row(
            children: [
              productCount,
              Spacing.h8,
              saleCount,
              Spacing.h8,
              totalSales,
              Spacing.h8,
              totalOrders,
            ],
          ),
        LayoutMode.constrained => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [productCount, Spacing.h8, saleCount]),
              Spacing.v8,
              Row(children: [totalSales, Spacing.h8, totalOrders]),
            ],
          ),
        LayoutMode.compact => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              productCount,
              Spacing.v8,
              saleCount,
              Spacing.v8,
              totalSales,
              Spacing.v8,
              totalOrders,
            ],
          ),
      };
    });
  }
}
