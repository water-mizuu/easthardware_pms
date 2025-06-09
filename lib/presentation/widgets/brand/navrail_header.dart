import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';

class LogoRow extends StatelessWidget {
  const LogoRow({super.key});

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.fromLTRB(8, 14, 8, 12);
    return Padding(
      padding: padding,
      child: LayoutBuilder(builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final logo = Image.asset(
          'assets/icons/app.png',
          height: 18,
          width: 18,
          fit: BoxFit.contain,
        );

        /// Is overflowing formula. Somehow it works. Don't modify.
        final isOverflowing = maxWidth < (padding.left + padding.right + 18) * 1.5;
        if (isOverflowing) {
          return Padding(padding: const EdgeInsets.only(top: 2), child: logo);
        }
        return Row(
          children: <Widget>[
            logo,
            const Expanded(child: SubheadingText("East Hardware", overflow: TextOverflow.clip))
          ].withSpacing(() => Spacing.h16),
        );
      }),
    );
  }
}
