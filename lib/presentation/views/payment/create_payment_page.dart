import 'dart:async';
import 'dart:math';

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
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/'
    'user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/payment/payment_method_form/'
    'payment_method_form_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/payment/print_receipt.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
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

    if (widget.invoice != null) {
      _paymentFormBloc.add(InvoiceChanged(widget.invoice!, isUserInput: false));
    }
  }

  @override
  void didUpdateWidget(covariant CreatePaymentPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.invoice != widget.invoice && widget.invoice != null) {
      _paymentFormBloc.add(InvoiceChanged(widget.invoice!, isUserInput: false));
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
              listenWhen: (p, c) => p.status != c.status && c.status == FormStatus.submitting,
              listener: (context, state) {
                final creator = context.read<AuthenticationBloc>().state.user!;
                final creationDate = DateTime.now();
                final payment = state
                    .copyWith(creatorId: creator.id, creationDate: creationDate) //
                    .toPayment();
                final invoice = state.invoice!;
                final paymentMethod = state.paymentMethod!;
                final discount = invoice.discountType == DiscountType.percentage
                    ? (invoice.amountDue * (invoice.discount ?? 0) / 100)
                    : (invoice.discount ?? 0.0);
                final openBalance = max(
                    0.0,
                    invoice.amountDue - //
                        discount -
                        payment.amount -
                        (invoice.amountPaid ?? 0) //
                    );
                final paymentDate = openBalance == 0 ? creationDate : null;

                final amountPaid = (invoice.amountPaid ?? 0) + payment.amount;
                final paidInvoice = invoice.copyWith(
                  amountPaid: amountPaid,
                  paymentMethod: paymentMethod.id!,
                  paymentDate: paymentDate,
                );
                context.read<InvoiceListBloc>().add(UpdateInvoiceEvent(paidInvoice));
                context.read<PaymentListBloc>().add(AddPaymentEvent(payment));
                context.read<UserLogListBloc>().add(
                      AddCreateEvent(
                        'Payment ${payment.id}',
                        creator,
                      ),
                    );
              },
            ),
            BlocListener<PaymentFormBloc, PaymentFormState>(
              listenWhen: (p, c) => p.status != c.status && c.status == FormStatus.printing,
              listener: (context, state) {
                final paymentFormState = context.read<PaymentFormBloc>().state;
                final paymentMethods = context.read<PaymentMethodListBloc>().state.paymentMethods;
                final invoiceListState = context.read<InvoiceListBloc>().state;

                // Validate form data before printing
                if (paymentFormState.invoice == null) {
                  context
                      .read<PaymentFormBloc>() //
                      .add(const InvoiceNumberErrorChanged('Please select an invoice.'));
                }

                if (paymentFormState.paymentMethod == null) {
                  context
                      .read<PaymentFormBloc>() //
                      .add(const PaymentMethodErrorChanged('Please select a payment method.'));
                }

                if (paymentFormState.paymentReference.isEmpty) {
                  context
                      .read<PaymentFormBloc>() //
                      .add(const ReferenceNumberErrorChanged('Please enter a reference number.'));
                  return;
                }

                if (paymentFormState.amount <= 0) {
                  context
                      .read<PaymentFormBloc>() //
                      .add(const AmountReceivedErrorChanged('Please enter a valid amount.'));
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
                  invoiceListState.invoiceProducts,
                );
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
                      child: AnimatedSingleChildScrollView(
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
          onPressed: () => context.read<PaymentFormBloc>().add(const PrintPaymentRequestEvent()),
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
                        const Text('Invoice No:', style: TextStyles.body),
                        Spacing.v8,
                        Builder(builder: (context) {
                          final (invoiceId, lastUpdated) = context.select((PaymentFormBloc b) =>
                              (b.state.invoice?.id, b.state.lastAutomatedUpdate));

                          return TextFormBox(
                            /// By only resetting whenever an automated update occurs,
                            ///   we ensure that the input field is not reset
                            ///   when the user manually selects an invoice.
                            key: ValueKey(lastUpdated),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+$')),
                              LengthLimitingTextInputFormatter(12)
                            ],
                            initialValue: invoiceId?.toString() ?? '',
                            onChanged: (value) {
                              if (invoices.map((e) => e.id.toString()).contains(value)) {
                                final invoice = invoices
                                    .where((invoice) => value == invoice.id.toString())
                                    .toList()
                                    .first;

                                context
                                    .read<PaymentFormBloc>()
                                    .add(InvoiceChanged(invoice, isUserInput: true));
                              } else {
                                context.read<PaymentFormBloc>().add(const InvoiceCleared());
                              }
                            },
                          );
                        }),
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
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^[a-zA-Z0-9\s]+$'),
                              replacementString:
                                  context.select((PaymentFormBloc b) => b.state.paymentReference),
                            ),
                            LengthLimitingTextInputFormatter(60)
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
                        AmountReceivedFormBox(invoice: invoice),
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

class AmountReceivedFormBox extends StatefulWidget {
  const AmountReceivedFormBox({
    super.key,
    required this.invoice,
  });

  final Invoice? invoice;

  @override
  State<AmountReceivedFormBox> createState() => _AmountReceivedFormBoxState();
}

class _AmountReceivedFormBoxState extends State<AmountReceivedFormBox> {
  final TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    _updateControllerValue();

    // Add listener to update bloc when text changes
    _controller.addListener(() {
      final amount = double.tryParse(_controller.text) ?? 0.0;
      context.read<PaymentFormBloc>().add(AmountChanged(amount));
    });
  }

  @override
  void didUpdateWidget(AmountReceivedFormBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoice != widget.invoice) {
      _updateControllerValue();
    }
  }

  void _updateControllerValue() {
    final invoice = widget.invoice;
    final amountDue = invoice?.amountDue ?? 0.0;
    final discount = invoice?.discountType == DiscountType.percentage
        ? (amountDue * (invoice?.discount ?? 0) / 100)
        : (invoice?.discount ?? 0.0);
    final amountPaid = invoice?.amountPaid ?? 0.0;

    final openBalance = max(
      0.0,
      amountDue - discount - amountPaid,
    );
    _controller.text = openBalance.toStringAsFixed(2);
    context.read<PaymentFormBloc>().add(AmountChanged(openBalance));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormBox(
      readOnly: widget.invoice == null,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d{0,2})?$')),
        LengthLimitingTextInputFormatter(12)
      ],
      controller: _controller,
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
              const Text('Existing Payments', style: TextStyles.subtitle),
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
        final payments = context
            .watch<PaymentListBloc>()
            .state
            .payments
            .where((payment) => payment.invoiceId == invoice?.id)
            .toList();
        final subtotal = invoice?.amountDue ?? 0.0;
        final discount = invoice?.discountType == DiscountType.percentage
            ? (subtotal * (invoice?.discount ?? 0) / 100)
            : (invoice?.discount ?? 0.0);
        final amountPaid = payments.fold(
          0.0,
          (previousValue, payment) => previousValue + payment.amount,
        );
        final amountReceied = context.watch<PaymentFormBloc>().state.amount.abs();
        final openBalance = max(0.0, subtotal - discount - amountPaid - amountReceied);
        final change = max(0.0, -(subtotal - discount - amountPaid - amountReceied));

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
                        CurrencyFormatter.full(subtotal),
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
                        CurrencyFormatter.full(discount),
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
                        CurrencyFormatter.full(amountPaid),
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
                            ? CurrencyFormatter.full(0)
                            : '-${CurrencyFormatter.full(context.watch<PaymentFormBloc>().state.amount.abs())}',
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
                        CurrencyFormatter.full(openBalance),
                        style: TextStyles.title,
                      ),
                    ],
                  ),
                  Spacing.v8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CHANGE:',
                        style: TextStyles.title.merge(TextStyles.onSurfaceVariant),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        CurrencyFormatter.full(change),
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
