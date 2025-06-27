import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart'
    show AccessLevel, DataStatus, DiscountType, FormStatus;
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_form/payment_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_list/payment_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_method_list/payment_method_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/payment/payment_method_form/payment_method_form_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/payment/print_receipt.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/payment_method_combo_box.dart';
import 'package:easthardware_pms/presentation/widgets/ui/loading_page.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CreatePaymentPage extends StatefulWidget {
  const CreatePaymentPage({
    super.key,
    required this.invoice,
  });

  final Invoice? invoice;

  @override
  State<CreatePaymentPage> createState() => _CreatePaymentPageState();
}

class _CreatePaymentPageState extends State<CreatePaymentPage> {
  late final PaymentFormBloc _paymentFormBloc;

  @override
  void initState() {
    super.initState();
    _paymentFormBloc = PaymentFormBloc();
    if (widget.invoice != null) _paymentFormBloc.add(InvoiceChanged(widget.invoice!));
  }

  @override
  void didUpdateWidget(covariant CreatePaymentPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.invoice != widget.invoice && widget.invoice != null) {
      _paymentFormBloc.add(InvoiceChanged(widget.invoice!));
    }
  }

  @override
  void dispose() {
    unawaited(_paymentFormBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _paymentFormBloc),
        BlocProvider(create: (context) => PaymentMethodFormCubit()),
      ],
      child: Builder(builder: (context) {
        return MultiBlocListener(
          listeners: [
            BlocListener<PaymentFormBloc, PaymentFormState>(
              listener: (context, state) {
                if (state.status == FormStatus.submitting) {
                  final creator = context.read<AuthenticationBloc>().state.user!;
                  final creationDate = DateTime.now();
                  final payment = state
                      .copyWith(creatorId: creator.id, creationDate: creationDate) //
                      .toPayment();
                  final invoice = state.invoice!.copyWith(
                    amountPaid: state.amount,
                    paymentMethod: state.paymentMethod!.id!,
                    paymentDate:
                        (state.invoice!.amountDue - state.amount) <= 0 ? creationDate : null,
                  );
                  context.read<InvoiceListBloc>().add(UpdateInvoiceEvent(invoice));
                  context.read<PaymentListBloc>().add(AddPaymentEvent(payment));
                  context.read<UserLogListBloc>().add(
                        AddCreateEvent(
                          'Payment ${payment.id}',
                          creator,
                        ),
                      );
                }
              },
            ),
            BlocListener<PaymentListBloc, PaymentListState>(
              listenWhen: (previous, current) {
                return previous.latest != current.latest && current.latest != null;
              },
              listener: (context, state) {
                context.read<PaymentFormBloc>().add(FormSubmittedEvent());
                context.read<AuthenticationBloc>().state.user!.accessLevel ==
                        AccessLevel.administrator
                    ? context.navigate(AppRoutes.admin.payment)
                    : context.navigate(AppRoutes.staff.billing);
              },
            ),
          ],
          child: BlocBuilder<PaymentFormBloc, PaymentFormState>(
            builder: (context, state) {
              if (state.status == FormStatus.submitting) {
                return const LoadingPage();
              }
              return const Padding(
                padding: AppPadding.panePadding,
                child: Column(
                  children: [
                    PageHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Spacing.v16,
                            PaymentForm(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final invoice = context.watch<PaymentFormBloc>().state.invoice;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(FluentIcons.back),

          /// Replace with payments page
          onPressed: () => context.read<AuthenticationBloc>().state.user!.accessLevel ==
                  AccessLevel.administrator
              ? context.navigate(AppRoutes.admin.payment)
              : context.navigate(AppRoutes.staff.billing),
        ),
        Spacing.h12,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Receive Payment',
              style: TextStyles.title,
            ),
            Spacing.v4,
            Text(
              'Invoice #${invoice?.id ?? 'N/A'}',
              style: TextStyles.caption,
            ),
          ],
        ),
        const Spacer(),
        TextButton(
          'Print Receipt',
          onPressed: () {
            final paymentFormState = context.read<PaymentFormBloc>().state;
            final paymentMethods = context.read<PaymentMethodListBloc>().state.paymentMethods;

            // Validate form data before printing
            if (paymentFormState.invoice == null) {
              // Show error - no invoice selected
              return;
            }

            if (paymentFormState.paymentMethod == null) {
              // Show error - no payment method selected
              return;
            }

            if (paymentFormState.paymentReference.isEmpty) {
              // Show error - no reference number
              return;
            }

            if (paymentFormState.amount <= 0) {
              // Show error - invalid amount
              return;
            }

            // Find the selected payment method details
            final selectedPaymentMethod = paymentMethods.firstWhere(
              (method) => method.id == paymentFormState.paymentMethod!.id,
              orElse: () => paymentFormState.paymentMethod!,
            );

            // Create a temporary payment object for the receipt
            final tempPayment = paymentFormState
                .copyWith(
                  id: 999999, // Temporary ID for preview
                  creatorId: context.read<AuthenticationBloc>().state.user!.id,
                  creationDate: DateTime.now(),
                )
                .toPayment();

            // Generate the receipt PDF
            generateReceiptPdf(
              tempPayment,
              paymentFormState.invoice!,
              selectedPaymentMethod,
            );
          },
        ),
        Spacing.h12,
        TextButtonFilled(
          'Save Payment',
          onPressed: (invoice != null && invoice.paymentDate == null)
              ? () => context.read<PaymentFormBloc>().add(const SavePaymentRequestEvent())
              : null,
        ),
      ],
    );
  }
}

class PaymentForm extends StatefulWidget {
  const PaymentForm({super.key});

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceListBloc>().state.invoices;

    return BlocBuilder<PaymentFormBloc, PaymentFormState>(
      builder: (context, state) {
        final invoice = state.invoice;

        return Container(
          constraints: const BoxConstraints(minHeight: 800),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Invoice", style: TextStyles.title),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Created on:',
                            style: TextStyles.body
                                .merge(TextStyles.onSurfaceVariant) //
                                .merge(TextStyles.strong),
                          ),
                          Spacing.h8,
                          invoice != null
                              ? Text(
                                  DateFormat.yMMMMd().format(invoice.creationDate),
                                  style: TextStyles.body //
                                      .merge(TextStyles.onSurfaceVariant)
                                      .merge(TextStyles.strong),
                                )
                              : Text('N/A',
                                  style: TextStyles.body
                                      .merge(TextStyles.onSurfaceVariant)
                                      .merge(TextStyles.strong))
                        ],
                      ),
                      if (invoice?.paymentDate != null) ...[
                        Spacing.v4,
                        Row(
                          children: [
                            Text(
                              'Closed on:',
                              style: TextStyles.body
                                  .merge(TextStyles.onSurfaceVariant) //
                                  .merge(TextStyles.strong),
                            ),
                            Spacing.h8,
                            Text(
                              DateFormat.yMMMMd().format(invoice!.paymentDate!),
                              style: TextStyles.body //
                                  .merge(TextStyles.onSurfaceVariant)
                                  .merge(TextStyles.strong),
                            )
                          ],
                        ),
                      ]
                    ],
                  )
                ],
              ),
              Spacing.v16,
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Invoice No.', style: TextStyles.body),
                        Spacing.v8,
                        TextFormBox(
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+$'))],
                          onChanged: (value) {
                            if (invoices.map((e) => e.id.toString()).contains(value)) {
                              final invoice = invoices
                                  .where((invoice) => value == invoice.id.toString())
                                  .toList()
                                  .first;
                              context.read<PaymentFormBloc>().add(InvoiceChanged(invoice));
                            } else {
                              context.read<PaymentFormBloc>().add(const InvoiceCleared());
                            }
                          },
                        ),
                        if (state.invoice != null && state.invoice!.paymentDate != null)
                          Text(
                            'Invoice has already been closed',
                            style: TextStyles.error.merge(TextStyles.body),
                          ),
                      ],
                    ),
                  ),
                  Spacing.h16,
                  Spacing.h16,
                  const Spacer(flex: 2)
                ],
              ),
              Spacing.v16,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            // const Icon(FluentIcons.contact, size: 12.0),
                            // Spacing.h4,
                            Text('Customer:', style: TextStyles.body.merge(TextStyles.strong)),
                            Spacing.h8,
                            invoice != null
                                ? Text(
                                    invoice.customerName.isEmpty ? 'N/A' : invoice.customerName,
                                    style: TextStyles.body,
                                  )
                                : Text('N/A',
                                    style: TextStyles.body
                                        .merge(TextStyles.onSurfaceVariant)
                                        .merge(TextStyles.strong))
                          ],
                        )
                      ],
                    ),
                  ),
                  Spacing.h16,
                  Expanded(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Invoice Date:',
                            style: TextStyles.body.merge(
                              TextStyles.strong,
                            ),
                          ),
                          Spacing.h8,
                          invoice != null
                              ? Text(
                                  DateFormat.yMMMMd().format(
                                    invoice.invoiceDate,
                                  ),
                                  style: TextStyles.body,
                                )
                              : Text('N/A',
                                  style: TextStyles.body
                                      .merge(TextStyles.onSurfaceVariant)
                                      .merge(TextStyles.strong))
                        ],
                      ),
                      Spacing.v12,
                      Row(
                        children: [
                          Text(
                            'Due Date:',
                            style: TextStyles.body.merge(
                              TextStyles.strong,
                            ),
                          ),
                          Spacing.h8,
                          invoice != null
                              ? Text(
                                  DateFormat.yMMMMd().format(
                                    invoice.dueDate,
                                  ),
                                  style: TextStyles.body,
                                )
                              : Text('N/A',
                                  style: TextStyles.body
                                      .merge(TextStyles.onSurfaceVariant)
                                      .merge(TextStyles.strong))
                        ],
                      )
                    ],
                  )),
                  const Spacer(flex: 2)
                ],
              ),
              Spacing.v16,
              Spacing.v16,
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Payment Method *",
                          style: TextStyles.body.merge(TextStyles.onSurface),
                        ),
                        Spacing.v8,
                        invoice != null
                            ? PaymentMethodComboBox(
                                value: context.select((PaymentFormBloc b) => b.state.paymentMethod),
                                onPaymentMethodSelected: (PaymentMethod method) {
                                  context.read<PaymentFormBloc>().add(
                                        PaymentMethodChanged(method),
                                      );
                                })
                            : PaymentMethodComboBox(
                                value: null,
                                onPaymentMethodSelected: (PaymentMethod method) {},
                                isDisabled: true,
                              ),
                        if (state.paymentMethodError != null)
                          Text(
                            context.watch<PaymentFormBloc>().state.paymentMethodError!,
                            style: TextStyles.error.merge(TextStyles.body),
                          ),
                      ],
                    ),
                  ),
                  Spacing.h16,
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Reference Number *",
                          style: TextStyles.body.merge(TextStyles.onSurface),
                        ),
                        Spacing.v8,
                        TextFormBox(
                          readOnly: invoice == null,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9\s]+$'))
                          ],
                          onChanged: (value) {
                            context.read<PaymentFormBloc>().add(PaymentReferenceChanged(value));
                          },
                        ),
                        if (state.referenceNumberError != null)
                          Text(
                            context.watch<PaymentFormBloc>().state.referenceNumberError!,
                            style: TextStyles.error.merge(TextStyles.body),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Amount Received *",
                          style: TextStyles.body.merge(TextStyles.onSurface),
                        ),
                        Spacing.v8,
                        TextFormBox(
                          readOnly: invoice == null,
                          initialValue: ((invoice?.amountDue ?? 0.0) - (invoice?.amountPaid ?? 0.0))
                              .toStringAsFixed(2),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d{0,2})?$'))
                          ],
                          onChanged: (value) {
                            context //
                                .read<PaymentFormBloc>()
                                .add(
                                  AmountChanged(double.tryParse(value) ?? 0.0),
                                );
                          },
                        ),
                        if (state.amountReceivedError != null)
                          Text(
                            context.watch<PaymentFormBloc>().state.amountReceivedError!,
                            style: TextStyles.error.merge(TextStyles.body),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Spacing.v16,
              Spacing.v16,
              const InvoiceProductTable(),
              Spacing.v16,
              const InvoicePaymentsTable(),
              Spacing.v16,
              const InvoiceSummary(),
            ],
          ),
        );
      },
    );
  }
}

class InvoiceProductTable extends StatelessWidget {
  const InvoiceProductTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentFormBloc, PaymentFormState>(
      listenWhen: (prev, curr) => prev.invoice != curr.invoice && curr.invoice != null,
      listener: (context, state) {
        context.read<InvoiceListBloc>().add(FetchInvoiceProductsEvent(state.invoice!.id!));
      },
      child: BlocBuilder<InvoiceListBloc, InvoiceListState>(
        bloc: context.read<InvoiceListBloc>(),
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.invoiceProducts != current.invoiceProducts,
        builder: (context, state) {
          if (state.status == DataStatus.loading) {
            return const Center(child: ProgressRing());
          }
          final invoice = context.watch<PaymentFormBloc>().state.invoice;
          if (invoice == null || state.invoiceProducts.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Items', style: TextStyles.subtitle),
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
              const Text('Items', style: TextStyles.subtitle),
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
                  decoration: BoxDecoration(
                    color: i % 2 == 0 ? const Color(0xFFFAFAFA) : null,
                    border: Border(bottom: BorderSide(color: Colors.grey[40], width: 1)),
                  ),
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
                          state.invoiceProducts[i].rate.toStringAsFixed(2),
                          style: TextStyles.body,
                        ),
                      ),
                      Spacing.h16,
                      Expanded(
                        child: Text(
                          state.invoiceProducts[i].amount.toStringAsFixed(2),
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
        },
      ),
    );
  }
}

class InvoicePaymentsTable extends StatelessWidget {
  const InvoicePaymentsTable({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentFormBloc, PaymentFormState>(
      buildWhen: (prev, curr) => prev.invoice != curr.invoice && curr.invoice != null,
      builder: (context, state) {
        final paymentListBloc = context.watch<PaymentListBloc>();
        final paymentFormState = context.watch<PaymentFormBloc>().state;
        final payments = paymentFormState.invoice != null
            ? paymentListBloc.state.payments
                .where((payment) => payment.invoiceId == paymentFormState.invoice!.id)
                .toList()
            : [];
        if (payments.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Payments', style: TextStyles.subtitle),
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
            const Text('Payments', style: TextStyles.subtitle),
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
                    flex: 1,
                    child: Text(
                      'PAYMENT',
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
                  const Spacer(flex: 3),
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
              Container(
                decoration: i % 2 == 0
                    ? BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        border: Border(bottom: BorderSide(color: Colors.grey[40], width: 1)),
                      )
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    SizedBox(width: 32.0, child: Center(child: Text('${i + 1}'))),
                    Spacing.h16,
                    Expanded(
                      child: Text(
                        'Payment # ${payments[i].id.toString()}',
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
                    const Spacer(flex: 3),
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
              if (i < payments.length - 1) Spacing.v8,
            ],
          ],
        );
      },
    );
  }
}

class InvoiceSummary extends StatelessWidget {
  const InvoiceSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceListBloc, InvoiceListState>(
      builder: (context, state) {
        if (state.status == DataStatus.loading) {
          return const Center(child: ProgressRing());
        }
        final invoice = context.read<PaymentFormBloc>().state.invoice;

        final total = invoice?.amountDue ?? 0.0;
        final discount = invoice?.discountType == DiscountType.percentage
            ? (total * (invoice?.discount ?? 0) / 100)
            : invoice?.discount;
        final subtotal = total - (discount ?? 0);

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
                        subtotal.toStringAsFixed(2),
                        style: TextStyles.body.merge(TextStyles.strong),
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
                        discount != null ? discount.toStringAsFixed(2) : '0.00',
                        style: TextStyles.body.merge(TextStyles.strong),
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
                        total.toStringAsFixed(2),
                        style: TextStyles.body.merge(TextStyles.strong),
                      ),
                    ],
                  ),
                  Spacing.v8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AMOUNT RECEIVED:',
                        style: TextStyles.body.merge(TextStyles.onSurfaceVariant),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        context.watch<PaymentFormBloc>().state.amount.abs() == 0
                            ? '0.00'
                            : '-${context.watch<PaymentFormBloc>().state.amount.abs().toStringAsFixed(2)}',
                        style: TextStyles.body.merge(TextStyles.strong),
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
                        (total -
                                context.watch<PaymentFormBloc>().state.amount -
                                (invoice?.amountPaid ?? 0))
                            .toStringAsFixed(2),
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
