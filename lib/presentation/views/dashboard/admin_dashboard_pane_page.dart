import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';

class AdminDashboardPanePage extends StatelessWidget {
  const AdminDashboardPanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const IntrinsicHeight(
              child: Padding(
                padding: AppPadding.panePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(),
                    SummarySection(),
                    GraphSection(),
                    TableSection(),
                  ],
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
            HeadingText('Admin Dashboard'),
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
    return const Row(children: []);
  }
}

class GraphSection extends StatelessWidget {
  const GraphSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(children: []);
  }
}

class TableSection extends StatelessWidget {
  const TableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(children: []);
  }
}

class ProductCountCard extends KPICard {
  const ProductCountCard({super.key, required super.value})
      : super(
          'Product Count',
          icon: const Icon(FluentIcons.product),
        );
}

class SaleCountCard extends KPICard {
  const SaleCountCard({super.key, required super.value})
      : super(
          'Low Stock Products',
          icon: const Icon(FluentIcons.product),
        );
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
