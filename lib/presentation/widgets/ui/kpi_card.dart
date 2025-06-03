import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';

class KPICard extends StatelessWidget {
  const KPICard(
    this.title, {
    required this.value,
    this.icon = const Icon(FluentIcons.square_shape),
    this.isExpanded = true,
    super.key,
  });

  final String title;
  final String value;
  final Icon icon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      color: Colors.white,
      padding: AppPadding.a16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: BodyText(title, overflow: TextOverflow.ellipsis)),
              icon,
            ].withSpacing(() => Spacing.h4),
          ),
          HeadingText(value),
        ].withSpacing(() => Spacing.v4),
      ),
    );

    if (isExpanded) {
      return Expanded(
        child: child,
      );
    }

    return child;
  }
}
