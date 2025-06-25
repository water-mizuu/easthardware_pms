import 'package:easthardware_pms/domain/models/invoice.dart';

import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';

class InvoiceInformationContentDialog extends StatelessWidget {
  const InvoiceInformationContentDialog({
    super.key,
    required this.context,
    required this.invoice,
  });

  final BuildContext context;
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxHeight: 600, maxWidth: 1200),
      title: DialogTitle(dialogContext: context, invoice: invoice),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BillingInformationDetails(invoice: invoice),
          Spacing.v16,
        ],
      ),
    );
  }
}

class DialogTitle extends StatelessWidget {
  const DialogTitle({
    super.key,
    required this.dialogContext,
    required this.invoice,
  });

  final BuildContext dialogContext;
  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Invoice #${invoice.id}', style: TextStyles.title),
        const Spacer(),
        Row(
          children: [
            Button(
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Row(
                  children: [
                    Icon(FluentIcons.edit),
                    Spacing.h12,
                    Text('Edit Invoice', style: TextStyles.body),
                  ],
                ),
              ),
              onPressed: () {
                // TODO:
                Navigator.of(dialogContext).pop();
              },
            ),
            Spacing.h8,
            Button(
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Row(
                  children: [
                    Icon(FluentIcons.print),
                    Spacing.h12,
                    Text('Print Invoice', style: TextStyles.body),
                  ],
                ),
              ),
              onPressed: () {
                // TODO:
                Navigator.of(dialogContext).pop();
              },
            ),
            Spacing.h8,
            Button(
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Icon(FluentIcons.chrome_close),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            Spacing.h8,
          ],
        ),
        Spacing.h4,
      ],
    );
  }
}

class BillingInformationDetails extends StatelessWidget {
  const BillingInformationDetails({
    super.key,
    required this.invoice,
  });

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text('Customer Name', style: TextStyles.onSurfaceVariant)),
                      const Spacer(),
                      Expanded(
                        child: Text(
                          invoice.customerName,
                          style: TextStyles.body,
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ],
                  ),
                  Spacing.v8,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text('Invoice Date', style: TextStyles.onSurfaceVariant)),
                      const Spacer(),
                      Expanded(
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(invoice.invoiceDate),
                          style: TextStyles.body,
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ],
                  ),
                  Spacing.v8,
                  Row(
                    children: [
                      Expanded(child: Text('Due Date', style: TextStyles.onSurfaceVariant)),
                      const Spacer(),
                      Expanded(
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(invoice.dueDate),
                          style: TextStyles.body,
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ],
                  ),
                  Spacing.v8,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Text('Reference Number',
                                        style: TextStyles.onSurfaceVariant)),
                                const Spacer(),
                                Expanded(
                                  child: Text(
                                    invoice.referenceNumber ?? 'N/A',
                                    style: TextStyles.body,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const Spacer(),
            Expanded(
                child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text('Memo', style: TextStyles.onSurfaceVariant)),
                    const Spacer(),
                    Expanded(
                      child: Text(
                        invoice.memo ?? 'N/A',
                        style: TextStyles.body,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                )
              ],
            )),
            const Spacer(flex: 3)
          ],
        )
      ],
    );
  }
}
