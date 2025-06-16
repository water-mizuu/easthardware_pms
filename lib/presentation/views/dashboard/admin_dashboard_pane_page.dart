import 'package:easthardware_pms/presentation/views/dashboard/cards/lower_stocked_products.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/product_count_card.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/recent_sales.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/sale_count_card.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/sales_overview.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/top_product_activity.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/total_orders_card.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/total_sales_card.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class AdminDashboardPanePage extends StatelessWidget {
  const AdminDashboardPanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSingleChildScrollView(
      child: Padding(
        padding: AppPadding.panePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(),
            const SummarySection(),
            const GraphsSection(),
            const SectionAlpha(),
            const RecentSales(),
          ].withSpacing(() => Spacing.v8),
        ),
      ),
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
      const totalSales = TotalSalesCard();
      const totalOrders = TotalOrdersCard();

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

class GraphsSection extends StatelessWidget {
  const GraphsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final layoutMode = context.watch<LayoutMode>();

    switch (layoutMode) {
      case LayoutMode.wide:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: SalesOverview()),
              Spacing.h8,
              Expanded(flex: 2, child: TopProductActivity()),
            ],
          ),
        );
      case LayoutMode.compact || LayoutMode.constrained:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: const SalesOverview(),
            ),
            Spacing.v8,
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: const TopProductActivity(),
            ),
          ],
        );
    }
  }
}

class SectionAlpha extends StatelessWidget {
  const SectionAlpha({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<LayoutMode>();

    return switch (mode) {
      LayoutMode.wide => const Row(
          children: [
            Expanded(child: LowerStockedProducts()),
            Spacing.h8,
            Expanded(child: LowerStockedProducts()),
          ],
        ),
      LayoutMode.constrained || LayoutMode.compact => const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LowerStockedProducts(),
            Spacing.v8,
            LowerStockedProducts(),
          ],
        ),
    };
  }
}
