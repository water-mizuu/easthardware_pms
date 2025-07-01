import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/utils/context_is_staff.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';

class ReportListPane extends StatelessWidget {
  const ReportListPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced header with description
          const HeadingText('Reports'),
          Spacing.v4,
          const GrayText('Access and generate business insights'),
          Spacing.v16,
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ProductServiceReports(),
                  BusinessSalesReports(),
                  BusinessExpensesReports(),
                  BusinessRevenueReports(),
                ].withSpacing(() => Spacing.v16), // Increased spacing between categories
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final headingPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12) - //
    const EdgeInsets.only(bottom: 12);

class ProductServiceReports extends StatelessWidget {
  const ProductServiceReports({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Card(
      borderRadius: BorderRadius.circular(8),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: headingPadding,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  FluentIcons.product_variant,
                  color: theme.accentColor,
                  size: 20,
                ),
                Spacing.h8,
                const DisplayText('Product and Service Reports'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReportItemCard(
                  icon: FluentIcons.product_list,
                  title: 'Inventory Report',
                  description: 'Track stock levels, product performance and inventory valuation',
                  onPressed: () {
                    if (context.isAdmin) {
                      context.navigate(AppRoutes.admin.inventoryReport);
                    }
                  },
                ),
              ].withSpacing(() => Spacing.v8),
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessSalesReports extends StatelessWidget {
  const BusinessSalesReports({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Card(
      backgroundColor: theme.cardColor,
      borderRadius: BorderRadius.circular(8),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: headingPadding,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  FluentIcons.chart_series, // Changed from unsupported icon
                  color: Color(0xFF0078D4),
                  size: 20,
                ),
                Spacing.h8,
                DisplayText('Business Sales Reports'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportItemCard(
                  icon: FluentIcons.document,
                  title: 'Invoice Sales Report',
                  description: 'Track individual invoice payments, due amounts, and payment status',
                  onPressed: () => context.navigate(AppRoutes.admin.invoiceSalesReport),
                ),
                ReportItemCard(
                  icon: FluentIcons.product_catalog,
                  title: 'Sales by Product',
                  description: 'Analyze which products are generating the most revenue',
                  onPressed: () => context.navigate(AppRoutes.admin.salesByProductReport),
                ),
                ReportItemCard(
                  icon: FluentIcons.product_release,
                  title: 'Sales by Category',
                  description: 'See which product categories are performing best',
                  onPressed: () => context.navigate(AppRoutes.admin.salesByCategoryReport),
                ),
              ].withSpacing(() => Spacing.v8),
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessExpensesReports extends StatelessWidget {
  const BusinessExpensesReports({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Card(
      backgroundColor: theme.cardColor,
      borderRadius: BorderRadius.circular(8),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: headingPadding,
            child: const Row(
              children: [
                Icon(
                  FluentIcons.money,
                  color: Color(0xFFD83B01),
                  size: 20,
                ),
                Spacing.h8,
                DisplayText('Business Expenses Reports'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportItemCard(
                  icon: FluentIcons.payment_card,
                  title: 'Expense Report',
                  description:
                      'Track and analyze all business expenses by category and time period',
                  onPressed: () => context.navigate(AppRoutes.admin.expenseReport),
                ),
              ].withSpacing(() => Spacing.v8),
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessRevenueReports extends StatelessWidget {
  const BusinessRevenueReports({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Card(
      backgroundColor: theme.cardColor,
      borderRadius: BorderRadius.circular(8),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: headingPadding,
            child: const Row(
              children: [
                Icon(
                  FluentIcons.chart_series, // Changed from unsupported icon
                  color: Color(0xFF107C10),
                  size: 20,
                ),
                Spacing.h8,
                DisplayText('Business Revenue Reports'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportItemCard(
                  icon: FluentIcons.chart_series,
                  title: 'Profit and Loss Report',
                  description: 'View comprehensive P&L statements across different time periods',
                  onPressed: () => context.navigate(AppRoutes.admin.profitLossReport),
                ),
                ReportItemCard(
                  icon: FluentIcons.timeline_progress,
                  title: 'Business Snapshot Report',
                  description: 'Get a quick overview of your business performance and key metrics',
                  onPressed: () => context.navigate(AppRoutes.admin.businessSnapshotReport),
                ),
              ].withSpacing(() => Spacing.v8),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportItemCard extends StatelessWidget {
  const ReportItemCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.onPressed,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Card(
      padding: EdgeInsets.zero,
      child: HoverButton(
        onPressed: onPressed,
        builder: (context, states) {
          final backgroundColor =
              states.isHovered ? theme.accentColor.withOpacity(0.01) : Colors.transparent;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: states.isHovered ? theme.accentColor.withOpacity(0.3) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 20,
                        color: theme.accentColor,
                      ),
                    ),
                  ),
                  Spacing.h12,
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.typography.bodyStrong,
                      ),
                      if (description != null) ...[
                        Spacing.v4,
                        Text(
                          description!,
                          style: theme.typography.caption?.copyWith(
                            color: theme.inactiveColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  FluentIcons.chevron_right,
                  size: 12,
                  color: states.isHovered ? theme.accentColor : theme.inactiveColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
