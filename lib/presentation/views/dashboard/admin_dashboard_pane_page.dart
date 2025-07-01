import 'package:easthardware_pms/presentation/views/dashboard/cards/expense_breakdown_card.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/latest_sales.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/lower_stocked_products.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/profit_and_loss_card.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/sales_overview.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/top_product_activity.dart';
import 'package:easthardware_pms/presentation/views/dashboard/dashboard_commons.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';

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
            const LatestSales(),
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

class GraphsSection extends StatelessWidget {
  const GraphsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutMode.builder((context, layoutMode, keys) {
      switch (layoutMode) {
        case LayoutMode.wide:
          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: SalesOverview(key: keys["salesOverview"]),
                ),
                Spacing.h8,
                Expanded(
                  flex: 2,
                  child: TopProductActivity(key: keys["topProductActivity"]),
                ),
              ],
            ),
          );
        case LayoutMode.compact || LayoutMode.constrained:
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SalesOverview(key: keys["salesOverview"]),
              ),
              Spacing.v8,
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: TopProductActivity(key: keys["topProductActivity"]),
              ),
            ],
          );
      }
    });
  }
}

class SectionAlpha extends StatelessWidget {
  const SectionAlpha({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutMode.builder((context, mode, keys) {
      return switch (mode) {
        LayoutMode.wide => IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: ExpenseBreakdownCard(key: keys['expensesBreakdown'])),
                Expanded(child: ProfitAndLossCard(key: keys['profitAndLoss'])),
                Expanded(child: LowerStockedProducts(key: keys['lowerStockedProducts'])),
              ].withSpacing(() => Spacing.h8),
            ),
          ),
        LayoutMode.constrained || LayoutMode.compact => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380.0),
                child: ExpenseBreakdownCard(key: keys['expensesBreakdown']),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380.0),
                child: ProfitAndLossCard(key: keys['profitAndLoss']),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380.0),
                child: LowerStockedProducts(key: keys['lowerStockedProducts']),
              ),
            ].withSpacing(() => Spacing.v8),
          ),
      };
    });
  }
}
