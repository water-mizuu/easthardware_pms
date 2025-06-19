import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';

class SystemBackupPage extends StatelessWidget {
  const SystemBackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PageHeader(),
        ].withSpacing(() => Spacing.v4),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const HeadingText('System Backup');
  }
}
