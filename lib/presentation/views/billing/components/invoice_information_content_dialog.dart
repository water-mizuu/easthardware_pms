import 'dart:math';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/category_list/category_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_list/payment_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/billing/components/print_invoice.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class InvoiceInformationContentDialog extends StatelessWidget {
  const InvoiceInformationContentDialog({
    super.key,
    required this.invoice,
  });

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(minHeight: 600, maxWidth: 1200),
      title: DialogTitle(dialogContext: context, invoice: invoice),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BillingInformationDetails(invoice: invoice),
            Spacing.v16,
            InvoiceProductTable(invoice: invoice),
            Spacing.v16,
            InvoicePaymentsTable(invoice: invoice),
            Spacing.v16,
            InvoiceSummary(invoice: invoice),
          ],
        ),
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
              onPressed: context.read<AuthenticationBloc>().state.user?.accessLevel ==
                      AccessLevel.administrator
                  ? () {
                      context.navigateWithExtra(AppRoutes.admin.editInvoice, invoice);
                      Navigator.of(dialogContext).pop();
                    }
                  : () {
                      context.navigateWithExtra(AppRoutes.staff.editInvoice, invoice);
                      Navigator.of(dialogContext).pop();
                    },
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
                Navigator.of(dialogContext).pop();

                final allCategories = context.read<CategoryListBloc>().state.categories;
                final allProducts = context.read<ProductListBloc>().state.allProducts;
                final invoiceProducts = (context.read<InvoiceListBloc>().state.invoiceProducts)
                    .where((p) => p.invoiceId == invoice.id)
                    .toList();

                generateInvoicePdf(invoice, invoiceProducts, allProducts, allCategories);
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
        const Text('Billing Information', style: TextStyles.title),
        Spacing.v12,
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
                  ),
                  Spacing.v8,
                ],
              ),
            ),
            const Spacer(),
            Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text('Memo', style: TextStyles.onSurfaceVariant)),
                        const Spacer(),
                        Expanded(
                          flex: 3,
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
            const Spacer(flex: 2)
          ],
        )
      ],
    );
  }
}

class InvoiceProductTable extends StatefulWidget {
  const InvoiceProductTable({super.key, required this.invoice});

  final Invoice invoice;

  @override
  State<InvoiceProductTable> createState() => _InvoiceProductTableState();
}

class _InvoiceProductTableState extends State<InvoiceProductTable> {
  @override
  void initState() {
    super.initState();
    // Load invoice products when the widget is initialized
    context.read<InvoiceListBloc>().add(FetchInvoiceProductsEvent(widget.invoice.id!));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InvoiceListBloc>().state;
    if (state.status == DataStatus.loading) {
      return const Center(child: ProgressRing());
    }
    if (state.invoiceProducts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Items', style: TextStyles.title),
          Spacing.v12,
          Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[40]),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: const Center(child: Text('No products found for this invoice.'))),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Items', style: TextStyles.title),
        Spacing.v12,
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[40], width: 1),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 32.0, child: Center(child: Text("#"))),
              Spacing.h16,
              Expanded(
                flex: 3,
                child: Text(
                  'PRODUCT',
                  style: TextStyles.body.merge(TextStyles.strong),
                ),
              ),
              Spacing.h16,
              Expanded(
                child: Text(
                  'QUANTITY',
                  style: TextStyles.body.merge(TextStyles.strong),
                ),
              ),
              Spacing.h16,
              Expanded(
                child: Text(
                  'RATE',
                  style: TextStyles.body.merge(TextStyles.strong),
                ),
              ),
              Spacing.h16,
              Expanded(
                child: Text(
                  'AMOUNT',
                  style: TextStyles.body.merge(TextStyles.strong),
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < state.invoiceProducts.length; i++) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: i % 2 == 0
                ? BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    border: Border(bottom: BorderSide(color: Colors.grey[40], width: 1)),
                  )
                : null,
            child: Row(
              children: [
                SizedBox(width: 32.0, child: Center(child: Text('${i + 1}'))),
                Spacing.h16,
                Expanded(
                  flex: 3,
                  child: Text(
                    state.invoiceProducts[i].productName,
                    style: TextStyles.body,
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: Text(
                    state.invoiceProducts[i].quantity.toString(),
                    style: TextStyles.body,
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: Text(
                    CurrencyFormatter.full(state.invoiceProducts[i].rate),
                    style: TextStyles.body,
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: Text(
                    CurrencyFormatter.full(state.invoiceProducts[i].amount),
                    style: TextStyles.body,
                  ),
                ),
              ],
            ),
          ),
          if (i < state.invoiceProducts.length - 1) Spacing.v8,
        ],
      ],
    );
  }
}

class InvoicePaymentsTable extends StatelessWidget {
  const InvoicePaymentsTable({super.key, required this.invoice});

  final Invoice invoice;
  @override
  Widget build(BuildContext context) {
    final paymentListBloc = context.watch<PaymentListBloc>();
    final payments =
        paymentListBloc.state.payments.where((payment) => payment.invoiceId == invoice.id).toList();
    if (payments.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Payments', style: TextStyles.title),
          Spacing.v12,
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[40]),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: const Center(
              child: Text('No payments found for this invoice.'),
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Payments', style: TextStyles.title),
        Spacing.v12,
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[40], width: 1),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 32.0, child: Center(child: Text("#"))),
              Spacing.h16,
              Expanded(
                flex: 2,
                child: Text(
                  'REFERENCE NUMBER',
                  style: TextStyles.body.merge(TextStyles.strong),
                ),
              ),
              Spacing.h16,
              Expanded(
                child: Text(
                  'PAYMENT DATE',
                  style: TextStyles.body.merge(TextStyles.strong),
                ),
              ),
              Spacing.h16,
              const Spacer(flex: 4),
              Spacing.h16,
              Expanded(
                child: Text(
                  'AMOUNT',
                  style: TextStyles.body.merge(TextStyles.strong),
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < payments.length; i++) ...[
          if (i > 0) Spacing.v8,
          Container(
            decoration: BoxDecoration(
              color: i % 2 == 0 ? const Color(0xFFFAFAFA) : null,
              border: Border(bottom: BorderSide(color: Colors.grey[40], width: 1)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                SizedBox(width: 32.0, child: Center(child: Text('${i + 1}'))),
                Spacing.h16,
                Expanded(
                  flex: 2,
                  child: Text(
                    payments[i].referenceNumber,
                    style: TextStyles.body,
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: Text(
                    DateFormat.yMMMMd().format(payments[i].creationDate),
                    style: TextStyles.body,
                  ),
                ),
                Spacing.h16,
                const Spacer(flex: 4),
                Spacing.h16,
                Expanded(
                  child: Text(
                    payments[i].amount.toString(),
                    style: TextStyles.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class InvoiceSummary extends StatelessWidget {
  const InvoiceSummary({super.key, required this.invoice});

  final Invoice invoice;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceListBloc, InvoiceListState>(
      builder: (context, state) {
        if (state.status == DataStatus.loading) {
          return const Center(child: ProgressRing());
        }

        final subtotal = invoice.amountDue;
        final discount = invoice.discountType == DiscountType.percentage
            ? (invoice.discount ?? 0.0) * subtotal / 100
            : invoice.discount;
        final amountPaid = invoice.amountPaid ?? 0;
        final openBalance = max(0.0, subtotal - (discount ?? 0.0) - amountPaid);

        final discountText =
            discount != null && discount > 0 ? CurrencyFormatter.full(discount, '- Php ') : '0.00';
        final amountPaidText =
            amountPaid > 0 ? CurrencyFormatter.full(amountPaid, '- Php ') : '0.00';

        return Row(
          children: [
            const Spacer(flex: 2),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SUBTOTAL:',
                        style: TextStyles.body.merge(TextStyles.onSurfaceVariant),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        CurrencyFormatter.full(subtotal, 'Php '),
                        style: TextStyles.body,
                      ),
                    ],
                  ),
                  Spacing.v8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DISCOUNT:',
                        style: TextStyles.body.merge(TextStyles.onSurfaceVariant),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        discountText,
                        style: TextStyles.body,
                      ),
                    ],
                  ),
                  Spacing.v8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AMOUNT PAID:',
                        style: TextStyles.body.merge(TextStyles.onSurfaceVariant),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        amountPaidText,
                        style: TextStyles.body,
                      ),
                    ],
                  ),
                  Spacing.v8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OPEN BALANCE:',
                        style: TextStyles.title.merge(TextStyles.onSurfaceVariant),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        CurrencyFormatter.full(openBalance, 'Php '),
                        style: TextStyles.title,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
