import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:fluent_ui/fluent_ui.dart';

class LogoRow extends StatelessWidget {
  const LogoRow({super.key});

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 0, vertical: 8);
    return Padding(
      padding: padding,
      child: LayoutBuilder(builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final logo = Image.asset(
          'assets/icons/logo.png',
          height: 64,
          width: 64,
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
            const Expanded(
              child: Text(
                "Prodcut Management System",
                style: TextStyles.strong,
                overflow: TextOverflow.clip,
              ),
            )
          ].withSpacing(() => Spacing.h16),
        );
      }),
    );
  }
}
