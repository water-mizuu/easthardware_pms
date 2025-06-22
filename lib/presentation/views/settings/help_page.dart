import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppPadding.panePadding,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(),
            Spacing.v16,
            _UserManualSection(),
            Spacing.v16,
            _FAQSection(),
          ],
        ),
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

class _UserManualSection extends StatelessWidget {
  const _UserManualSection();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Manual',
          style: FluentTheme.of(context).typography.subtitle?.copyWith(
                fontWeight: FontWeight.normal,
              ),
        ),
        Spacing.v16,
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _UserManualCard(
                icon: FluentIcons.product_catalog,
                title: 'Inventory Management',
                description: 'Add, update, and track hardware products in your inventory system.'),
            _UserManualCard(
                icon: FluentIcons.shop,
                title: 'Sales & Order Processing',
                description: 'Creating and Tracking of Sales, and Orders data.'),
            _UserManualCard(
                icon: FluentIcons.chart,
                title: 'Reports & Analytics',
                description:
                    'Generate inventory reports, sales analytics, and business performance metrics.'),
            _UserManualCard(
                icon: FluentIcons.settings,
                title: 'System Security & Settings',
                description: 'Configure system settings, access level, etc.'),
          ],
        ),
      ],
    );
  }
}

class _UserManualCard extends StatelessWidget {
  const _UserManualCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Card(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: 250,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 36.0,
                color: theme.accentColor,
              ),
            ),
            Spacing.v16,
            Text(
              title,
              style: theme.typography.body?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Spacing.v8,
            Text(
              description,
              style: theme.typography.body?.copyWith(
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FAQSection extends StatelessWidget {
  const _FAQSection();

  static const List<({String question, String answer})> _faqItems = [
    (
      question: 'What is EastHardware Product Management System (PMS)?',
      answer:
          'EastHardware PMS is a comprehensive product management system designed specifically for EastHardware to efficiently manage inventory, process sales, and generate reports.'
    ),
    (
      question: 'How do I add new products to inventory?',
      answer:
          'Navigate to the Inventory section, click on "Add New Product", fill in the product details including name, SKU, price, quantity, and supplier information, then click Save.'
    ),
    (
      question: 'How can I generate reports?',
      answer:
          'Go to the Reports section, select which Reports you want to generate, then click "Generate Report".'
    ),
    (
      question: 'How can I set up low stock alerts?',
      answer:
          'Go to Settings > Inventory Settings > Alerts, enable "Low Stock Notifications", set your preferred threshold levels for each product category, and save your changes.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions:',
          style: FluentTheme.of(context).typography.subtitle?.copyWith(
                fontWeight: FontWeight.normal,
              ),
        ),
        Spacing.v16,
        ..._faqItems.map((faq) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FAQExpander(
                  question: faq.question,
                  answer: faq.answer,
                ),
                if (faq != _faqItems.last) Spacing.v8,
              ],
            )),
      ],
    );
  }
}

class _FAQExpander extends StatelessWidget {
  const _FAQExpander({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Expander(
      header: Text(
        question,
        style: theme.typography.body?.copyWith(
          fontWeight: FontWeight.normal,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          answer,
          style: theme.typography.body,
        ),
      ),
    );
  }
}
