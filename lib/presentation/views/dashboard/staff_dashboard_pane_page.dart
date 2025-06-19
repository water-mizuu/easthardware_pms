import 'package:easthardware_pms/presentation/views/dashboard/cards/latest_sales.dart';
import 'package:easthardware_pms/presentation/views/dashboard/dashboard_commons.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';

class StaffDashboardPanePage extends StatelessWidget {
  const StaffDashboardPanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSingleChildScrollView(
      child: Padding(
        padding: AppPadding.panePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(),
            const SummarySection(),
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
            HeadingText('Staff Dashboard'),
            GrayText('Overview of the system'),
          ],
        ),
      ],
    );
  }
}
