import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:fluent_ui/fluent_ui.dart';

class TotalOrdersCard extends KPICard {
  const TotalOrdersCard({super.key, required super.value})
      : super(
          'Total Orders',
          icon: const Icon(FluentIcons.market_down),
        );
}
