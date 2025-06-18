import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:fluent_ui/fluent_ui.dart';

class PaymentsPanePage extends StatelessWidget {
  const PaymentsPanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppPadding.panePadding,
      child: Column(
        children: [
          PageHeader(),
          // SizedBox(height: 16),
          // PaginatedTable.sample(isExpanded: true),
        ],
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
        Text(
          'Payments',
          style: TextStyles.title,
        ),
        Spacer(),
      ],
    );
  }
}
