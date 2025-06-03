import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';

class LogoRow extends StatelessWidget {
  const LogoRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
      child: Row(
        children: <Widget>[
          Image.asset(
            'assets/icons/app.png',
            height: 18,
            width: 18,
          ),
          const SubheadingText("East Hardware")
        ].withSpacing(() => Spacing.h16),
      ),
    );
  }
}
