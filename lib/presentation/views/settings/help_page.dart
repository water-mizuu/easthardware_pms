import 'package:easthardware_pms/presentation/widgets/info_card.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.panePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PageHeader(),
          SystemInfoSection(),
          VersionInfoSection(),
          DevelopersSection(),
        ].withSpacing(() => Spacing.v4),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const HeadingText('Help');
  }
}

class SystemInfoRow extends StatelessWidget {
  const SystemInfoRow({
    super.key,
    required this.label,
    required this.value,
  });
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: FluentTheme.of(context).typography.body?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: FluentTheme.of(context).typography.body,
          ),
        ),
      ],
    );
  }
}

class SystemInfoSection extends StatelessWidget {
  const SystemInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoCard(
      title: 'System and Software Versions',
      child: Column(
        children: [
          SystemInfoRow(label: 'System Version:', value: '1.0.0'),
          Spacing.v8,
          SystemInfoRow(label: 'Flutter Version:', value: '3.24.3'),
          Spacing.v8,
          SystemInfoRow(label: 'SQLite Version:', value: '2.3'),
        ],
      ),
    );
  }
}

class DeveloperInfo extends StatelessWidget {
  const DeveloperInfo({
    super.key,
    required this.name,
    required this.description,
  });
  final String name;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: FluentTheme.of(context).typography.body?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Spacing.v4,
        Text(
          description,
          style: FluentTheme.of(context).typography.body?.copyWith(
                color: FluentTheme.of(context).resources.textFillColorSecondary,
              ),
        ),
      ],
    );
  }
}

class VersionInfoSection extends StatelessWidget {
  const VersionInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Version Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Version: 1.0.0',
            style: FluentTheme.of(context).typography.body,
          ),
          Spacing.v8,
          Text(
            'Released: 2025',
            style: FluentTheme.of(context).typography.body?.copyWith(
                  color: FluentTheme.of(context).resources.textFillColorSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class DevelopersSection extends StatelessWidget {
  const DevelopersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoCard(
      title: 'System Developers',
      child: Column(
        children: [
          DeveloperInfo(
            name: 'Mac Kenzie B. Cerenio',
            description: '3rd Year BSCS - Technological Institute of the Philippines',
          ),
          Spacing.v16,
          DeveloperInfo(
            name: 'John Vincent M. Siggayo',
            description: '3rd Year BSCS - Technological Institute of the Philippines',
          ),
          Spacing.v16,
          DeveloperInfo(
            name: 'John Michael T. Zuñiga',
            description: '3rd Year BSCS - Technological Institute of the Philippines',
          ),
        ],
      ),
    );
  }
}
