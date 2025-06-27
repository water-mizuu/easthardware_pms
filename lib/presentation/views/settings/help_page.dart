import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/layout_mode_provider.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:fluent_ui/fluent_ui.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppPadding.panePadding,
      child: AnimatedSingleChildScrollView(
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Spacing.v16,
        LayoutMode.builder((context, mode, keys) {
          final cards = [
            _UserManualCard(
              icon: FluentIcons.product_catalog,
              title: 'Inventory Management',
              description: 'Add, update, and track hardware products in your inventory system.',
              key: keys['0'],
            ),
            _UserManualCard(
              icon: FluentIcons.shop,
              title: 'Sales & Order Processing',
              description: 'Creating and Tracking of Sales, and Orders data.',
              key: keys['1'],
            ),
            _UserManualCard(
              icon: FluentIcons.chart,
              title: 'Reports & Analytics',
              description:
                  'Generate inventory reports, sales analytics, and business performance metrics.',
              key: keys['2'],
            ),
            _UserManualCard(
              icon: FluentIcons.settings,
              title: 'System Security & Settings',
              description: 'Configure system settings, access level, etc.',
              key: keys['3'],
            ),
          ];

          switch (mode) {
            case LayoutMode.wide:
              return IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final card in cards) Expanded(child: card),
                  ].withSpacing(() => Spacing.h8),
                ),
              );
            case LayoutMode.constrained:
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: cards[0]),
                        Spacing.h8,
                        Expanded(child: cards[1]),
                      ],
                    ),
                  ),
                  Spacing.v8,
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: cards[2]),
                        Spacing.h8,
                        Expanded(child: cards[3]),
                      ],
                    ),
                  ),
                ],
              );
            case LayoutMode.compact:
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final card in cards) card,
                ].withSpacing(() => Spacing.v8),
              );
          }
        }),
      ],
    );
  }
}

class _UserManualCard extends StatelessWidget {
  const _UserManualCard({
    super.key,
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
    );
  }
}

class _FAQSection extends StatelessWidget {
  const _FAQSection();

  static const List<({String section, List<({String question, String answer})> items})>
      _newFaqItems = [
    (
      section: "General System Questions",
      items: [
        (
          question: "Q: What is EastHardware Product Management System (PMS)?",
          answer:
              "A: EastHardware PMS is a comprehensive product management system designed specifically for EastHardware to efficiently manage inventory, process sales, and generate reports."
        ),
        (
          question: "Q: How do I connect to the server?",
          answer:
              "A: Navigate to the connection setup screen, select \"Client Mode\", enter the server IP address and port, then click \"Connect to Server\"."
        ),
        (
          question: "Q: What's the difference between Server Mode and Client Mode?",
          answer:
              "A: Server Mode hosts the database locally, while Client Mode connects to an existing server. Use Server Mode for the main system, Client Mode for additional workstations."
        ),
      ]
    ),
    (
      section: "Inventory Management",
      items: [
        (
          question: "Q: How do I add new products to inventory?",
          answer:
              "A: Navigate to Inventory → Add New Product, fill in the product details including name, SKU, category, price, quantity, and unit information, then click Save."
        ),
        (
          question: "Q: How do I manage product categories?",
          answer:
              "A: Go to Inventory → Manage Categories to add, edit, or delete product categories. You can also see how many products are in each category."
        ),
        (
          question: "Q: What is Critical Level and how does it work?",
          answer:
              "A: Critical Level is the minimum stock quantity that triggers low stock alerts. When product quantity falls below this level, the system will mark it as \"Low Stock\"."
        ),
        (
          question: "Q: How do I update product quantities?",
          answer:
              "A: Navigate to the Inventory section, find the product, click \"Edit Product\", update the quantity field, and save changes."
        ),
        (
          question: "Q: What are Secondary Units?",
          answer:
              "A: Secondary Units allow you to sell products in different unit measurements (e.g., selling screws by piece or by box)."
        ),
      ]
    ),
    (
      section: "Sales & Billing",
      items: [
        (
          question: "Q: How do I create a new invoice?",
          answer:
              "A: Go to Billing → Create Invoice, add customer information, select products, enter quantities and rates, then click \"Save Invoice\" or \"Save and Receive Payment\"."
        ),
        (
          question: "Q: How do I receive payment for an invoice?",
          answer:
              "A: From the invoice list, click on an invoice and select \"Receive Payment\", or use \"Save and Receive Payment\" when creating a new invoice."
        ),
        (
          question: "Q: How do I manage payment methods?",
          answer:
              "A: Navigate to Billing → Manage Payment Methods to add, edit, or delete available payment options."
        ),
        (
          question: "Q: Can I edit an invoice after it's created?",
          answer:
              "A: Yes, go to the invoice list, select the invoice, and click \"Edit Invoice\" to make changes."
        ),
      ]
    ),
    (
      section: "Orders & Expenses",
      items: [
        (
          question: "Q: How do I create a restock order?",
          answer:
              "A: Go to Orders → Create Restock Order, select products that need restocking, enter quantities and supplier information, then save the order."
        ),
        (
          question: "Q: How do I create an expense order?",
          answer:
              "A: Navigate to Orders → Create Expense Order, select the expense type, enter payee information and amount, then save the order."
        ),
        (
          question: "Q: How do I manage expense types?",
          answer:
              "A: Go to Orders → Manage Expense Type to add, edit, or delete different categories of business expenses."
        ),
      ]
    ),
    (
      section: "User Management & Security",
      items: [
        (
          question: "Q: How do I register a new user?",
          answer:
              "A: Go to Security → Register User, fill in user details including name, username, access level, password, and security questions, then click \"Create User\"."
        ),
        (
          question: "Q: What are the different access levels?",
          answer:
              "A: The system has Administrator and Staff access levels. Administrators have full system access, while Staff have limited permissions."
        ),
        (
          question: "Q: How do I reset a user's password?",
          answer:
              "A: Use the password reset feature by entering the username and answering the security questions associated with that account."
        ),
        (
          question: "Q: How do I view user activity logs?",
          answer:
              "A: Navigate to Security → User Logs to see all user activities, filter by date range, user, or access level."
        ),
      ]
    ),
    (
      section: "Reports & Analytics",
      items: [
        (
          question: "Q: How can I generate reports?",
          answer:
              "A: Go to the Reports section, select the type of report you want (Business Snapshot, Sales Overview, etc.), set your date range and filters, then click \"Generate Report\"."
        ),
        (
          question: "Q: How do I view sales analytics?",
          answer:
              "A: Navigate to Dashboard to see sales overview charts, or go to Reports → Business Snapshot for detailed sales analytics and trends."
        ),
        (
          question: "Q: Can I export reports to PDF?",
          answer:
              "A: Yes, most reports have an \"Export to PDF\" option available in the report generation interface."
        ),
      ]
    ),
    (
      section: "System Backup & Maintenance",
      items: [
        (
          question: "Q: How do I backup the database?",
          answer:
              "A: Go to System Backup, select backup options (encrypted or unencrypted), and click \"Create Backup\" to save your data."
        ),
        (
          question: "Q: How do I restore from a backup?",
          answer:
              "A: In the System Backup section, select an existing backup file and click \"Restore\" to restore your database."
        ),
        (
          question: "Q: How do I check system information?",
          answer:
              "A: Navigate to Settings → About to view system version, database information, and developer details."
        ),
      ]
    ),
    (
      section: "Search & Navigation",
      items: [
        (
          question: "Q: How do I search for products across the system?",
          answer:
              "A: Use the Search feature to find products, invoices, orders, and other data across all system modules."
        ),
        (
          question: "Q: How do I archive old records?",
          answer:
              "A: Navigate to System Archive to view and manage archived products, users, and other data that's no longer actively used."
        ),
      ]
    ),
    (
      section: "Troubleshooting",
      items: [
        (
          question: "Q: What should I do if I lose connection to the server?",
          answer:
              "A: The system will automatically attempt to reconnect. You can also click \"Retry Now\" in the connection lost dialog or wait for automatic reconnection attempts."
        ),
        (
          question: "Q: How do I get help with the system?",
          answer:
              "A: Go to Settings → Help for user manuals and frequently asked questions, or Settings → About for system information."
        ),
        (
          question: "Q: What do I do if I can't remember my password?",
          answer:
              "A: Use the \"Forgot Password\" link on the login screen and answer your security questions to reset your password."
        ),
      ]
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
        Spacing.v32,
        for (final faq in _newFaqItems)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubheadingText(faq.section),
              Spacing.v8,
              for (final (index, item) in faq.items.indexed) ...[
                if (index > 0) Spacing.v4,
                _FAQExpander(
                  question: item.question,
                  answer: item.answer,
                )
              ],
              if (faq != _newFaqItems.last) Spacing.v16,
            ],
          ),
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
