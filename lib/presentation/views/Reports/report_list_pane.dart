import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/info_card.dart';
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
          const HeadingText('Reports'),
          Spacing.v8,
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ProductServiceReports(),
                  BusinessSalesReports(),
                  BusinessExpensesReports(),
                  BusinessRevenueReports(),
                ].withSpacing(() => Spacing.v8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductServiceReports extends StatelessWidget {
  const ProductServiceReports({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Product and Service Reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportItemCard(
            title: 'Inventory Report',
            onPressed: () {
              /// FIXME: Add support for staff access

              if (context.isAdmin) {
                context.navigate(AppRoutes.admin.inventoryReport);
              }
            },
          ),
        ].withSpacing(() => Spacing.v4),
      ),
    );
  }
}

class BusinessSalesReports extends StatelessWidget {
  const BusinessSalesReports({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Business Sales Reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportItemCard(
            title: 'Sales by Product',
            // onPressed: () => context.navigate(AppRoutes.salesByProductReport),
          ),
          const ReportItemCard(
            title: 'Sales by Category',
            // onPressed: () => context.navigate(AppRoutes.salesByCategoryReport),
          ),
        ].withSpacing(() => Spacing.v4),
      ),
    );
  }
}

class BusinessExpensesReports extends StatelessWidget {
  const BusinessExpensesReports({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Business Expenses Reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportItemCard(
            title: 'Expense Report',
            // onPressed: () => context.navigate(AppRoutes.expenseReport),
          ),
        ].withSpacing(() => Spacing.v4),
      ),
    );
  }
}

class BusinessRevenueReports extends StatelessWidget {
  const BusinessRevenueReports({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Business Revenue Reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportItemCard(
            title: 'Profit and Loss Report',
            // onPressed: () => context.navigate(AppRoutes.profitLossReport),
          ),
          const ReportItemCard(
            title: 'Business Snapshot Report',
            // onPressed: () => context.navigate(AppRoutes.businessSnapshotReport),
          ),
        ].withSpacing(() => Spacing.v4),
      ),
    );
  }
}

class ReportItemCard extends StatelessWidget {
  const ReportItemCard({
    super.key,
    required this.title,
    this.onPressed,
  });
  final String title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: EdgeInsets.zero,
      child: HoverButton(
        onPressed: onPressed,
        builder: (context, states) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: states.isHovered
                  ? FluentTheme.of(context).resources.subtleFillColorSecondary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: FluentTheme.of(context).typography.body,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
