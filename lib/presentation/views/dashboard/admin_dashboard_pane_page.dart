import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminDashboardPanePage extends StatelessWidget {
  const AdminDashboardPanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: AppPadding.panePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageHeader(),
                    const SummarySection(),
                    const GraphSection(),
                    const TopProductsSection(),
                  ].withSpacing(() => Spacing.v16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeadingText('Dashboard'),
            GrayText('Overview of the system'),
          ],
        ),
      ],
    );
  }
}

class SummarySection extends StatelessWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutMode.builder((context, mode) {
      const productCount = ProductCountCard();
      const saleCount = SaleCountCard();
      const totalSales = TotalSalesCard(value: "Hi");
      const totalOrders = TotalOrdersCard(value: "Hi");

      return switch (mode) {
        LayoutMode.wide => const Row(
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
        LayoutMode.constrained => const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [productCount, Spacing.h8, saleCount]),
              Spacing.v8,
              Row(children: [totalSales, Spacing.h8, totalOrders]),
            ],
          ),
        LayoutMode.compact => const Column(
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

class GraphSection extends StatelessWidget {
  const GraphSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(children: []);
  }
}

class TopProductsSection extends StatelessWidget {
  const TopProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(children: []);
  }
}

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

class SaleCountCard extends StatelessWidget {
  const SaleCountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.select((ProductListBloc b) => b.state.allProducts);
    final lowStockProducts = products.where((p) => p.quantity < p.deadStockThreshold).length;

    return KPICard(
      'Low Stock Products',
      value: lowStockProducts.toString(),
      icon: const Icon(FluentIcons.product),
    );
  }
}

class TotalSalesCard extends KPICard {
  const TotalSalesCard({super.key, required super.value})
      : super(
          'Total Sales',
          icon: const Icon(FluentIcons.product_warning),
        );
}

class TotalOrdersCard extends KPICard {
  const TotalOrdersCard({super.key, required super.value})
      : super(
          'Total Orders',
          icon: const Icon(FluentIcons.market_down),
        );
}
