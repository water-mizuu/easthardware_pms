import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart' show AccessLevel, DataStatus;
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_form/payment_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_method_list/payment_method_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/payment/payment_method_form/cubit/payment_method_form_cubit.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/loading_page.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/boxed.dart';
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

  final Invoice invoice;

  @override
  State<CreatePaymentPage> createState() => _CreatePaymentPageState();
}

class _CreatePaymentPageState extends State<CreatePaymentPage> {
  late final PaymentFormBloc _paymentFormBloc;

  @override
  void initState() {
    super.initState();
    _paymentFormBloc = PaymentFormBloc();
    _paymentFormBloc.add(InvoiceChanged(widget.invoice));
  }

  @override
  void didUpdateWidget(covariant CreatePaymentPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.invoice != widget.invoice) {
      _paymentFormBloc.add(InvoiceChanged(widget.invoice));
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
        return BlocBuilder<PaymentFormBloc, PaymentFormState>(
          builder: (context, state) {
            if (state.invoice == null) {
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
        );
      }),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentFormBloc, PaymentFormState>(
      builder: (context, state) {
        final invoice = state.invoice;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.back),

              /// Replace with payments page
              onPressed: () => context.read<AuthenticationBloc>().state.user!.accessLevel ==
                      AccessLevel.administrator
                  ? context.navigate(AppRoutes.admin.billing)
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
                  'Invoice #${invoice?.id}',
                  style: TextStyles.caption,
                ),
              ],
            ),
            const Spacer(),
            TextButtonFilled(
              'Save Payment',
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }
}

class PaymentForm extends StatefulWidget {
  const PaymentForm({super.key});

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  late final _flyoutController = FlyoutController();

  @override
  Widget build(BuildContext context) {
    final invoice = context.select((PaymentFormBloc b) => b.state.invoice)!;
    final paymentMethods = context.select((PaymentMethodListBloc b) => b.state.paymentMethods);
    printBoxed(paymentMethods);

    final comboBoxItems = [
      ComboBoxItem(
        value: null,
        onTap: () {},
        child: FlyoutTarget(
          controller: _flyoutController,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add New Payment Method', style: TextStyles.body),
              Icon(FluentIcons.add, size: 12.0),
            ],
          ),
        ),
      ),
      for (final method in paymentMethods) ...[
        ComboBoxItem(
          value: method,
          child: Text(method.name, style: TextStyles.body),
          onTap: () {
            context.read<PaymentFormBloc>().add(
                  PaymentMethodChanged(
                    method.id!,
                    method.name,
                  ),
                );
          },
        ),
      ],
    ];
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
              Row(
                children: [
                  Text(
                    'Created on:',
                    style: TextStyles.body
                        .merge(TextStyles.onSurfaceVariant) //
                        .merge(TextStyles.strong),
                  ),
                  Spacing.h8,
                  Text(
                    DateFormat.yMMMMd().format(invoice.creationDate),
                    style: TextStyles.body //
                        .merge(TextStyles.onSurfaceVariant)
                        .merge(TextStyles.strong),
                  )
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
                      controller: TextEditingController(text: invoice.id.toString()),
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
                        Text(
                          invoice.customerName.isEmpty ? 'N/A' : invoice.customerName,
                          style: TextStyles.body,
                        )
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
                      Text(
                        DateFormat.yMMMMd().format(
                          invoice.invoiceDate,
                        ),
                        style: TextStyles.body,
                      )
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
                      Text(
                        DateFormat.yMMMMd().format(
                          invoice.dueDate,
                        ),
                        style: TextStyles.body,
                      )
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
                      "Payment Method",
                      style: TextStyles.body.merge(TextStyles.onSurface),
                    ),
                    Spacing.v8,
                    ComboBox(
                      placeholder: Text(
                        'Select Payment Method',
                        style: TextStyles.body.merge(TextStyles.onSurfaceVariant),
                      ),
                      isExpanded: true,
                      items: [...comboBoxItems],
                      onChanged: (value) {
                        if (value is PaymentMethod) {
                          context
                              .read<PaymentFormBloc>()
                              .add(PaymentMethodChanged(value.id!, value.name));
                        } else {
                          unawaited(_flyoutController.showFlyout(
                            autoModeConfiguration: FlyoutAutoConfiguration(
                              preferredMode: FlyoutPlacementMode.bottomRight,
                            ),
                            builder: (flyoutContext) {
                              return FlyoutContent(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 400.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text('New Payment Method', style: TextStyles.subtitle),
                                      Spacing.v16,
                                      const Text('Name', style: TextStyles.body),
                                      Spacing.v8,
                                      TextFormBox(
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Payment method name cannot be empty';
                                          }
                                          if (value.length < 3) {
                                            return 'Payment method name must be at least 3 characters long';
                                          }
                                          if (paymentMethods.map((e) => e.name).contains(value)) {
                                            return 'Payment method already exists';
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^[a-zA-Z0-9\s]+$'))
                                        ],
                                        onChanged: (value) {
                                          context
                                              .read<PaymentMethodFormCubit>()
                                              .onFormNameChanged(value);
                                        },
                                      ),
                                      Spacing.v16,
                                      Row(
                                        children: [
                                          const Spacer(flex: 2),
                                          TextButtonFilled(
                                            'Save',
                                            onPressed: () {
                                              final bloc = context.read<PaymentMethodListBloc>();
                                              final paymentMethodFormState =
                                                  context.read<PaymentMethodFormCubit>().state;
                                              final paymentMethod =
                                                  paymentMethodFormState.toPaymentMethod();
                                              bloc.add(AddPaymentMethodEvent(paymentMethod));
                                            },
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ));
                        }
                      },
                    )
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
                      "Reference Number",
                      style: TextStyles.body.merge(TextStyles.onSurface),
                    ),
                    Spacing.v8,
                    TextFormBox(
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9\s]+$'))
                      ],
                      onChanged: (value) {
                        context.read<PaymentFormBloc>().add(PaymentReferenceChanged(value));
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Reference number cannot be empty';
                        }
                        return null;
                      },
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
                      "Amount Received",
                      style: TextStyles.body.merge(TextStyles.onSurface),
                    ),
                    Spacing.v8,
                    TextFormBox(
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Reference number cannot be empty';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Container(
          //   padding: const EdgeInsets.symmetric(vertical: 8.0),
          //   decoration: BoxDecoration(
          //     border: Border(
          //       bottom: BorderSide(color: Colors.grey[40], width: 1),
          //     ),
          //   ),
          //   child: const SizedBox.shrink(),
          // ),
          // const Text(
          //   "Items",
          //   style: TextStyles.title,
          // ),
          Spacing.v16,
          Spacing.v16,
          const InvoiceProductTable(),
          Spacing.v16,
          const InvoiceProductSummary(),
        ],
      ),
    );
  }
}

class InvoiceProductTable extends StatefulWidget {
  const InvoiceProductTable({super.key});

  @override
  State<InvoiceProductTable> createState() => _InvoiceProductTableState();
}

class _InvoiceProductTableState extends State<InvoiceProductTable> {
  @override
  void initState() {
    super.initState();
    final invoice = context.read<PaymentFormBloc>().state.invoice!;
    context.read<InvoiceListBloc>().add(FetchInvoiceProductsEvent(invoice.id!));
  }

  @override
  void didChangeDependencies() {
    final invoice = context.read<PaymentFormBloc>().state.invoice;
    if (invoice != null && context.read<InvoiceListBloc>().state.status == DataStatus.initial) {
      context.read<InvoiceListBloc>().add(FetchInvoiceProductsEvent(invoice.id!));
    }
    // Take the payments on the invoice
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvoiceListBloc, InvoiceListState>(
      bloc: context.read<InvoiceListBloc>(),
      buildWhen: (previous, current) =>
          previous.status != current.status || previous.invoiceProducts != current.invoiceProducts,
      builder: (context, state) {
        if (state.status == DataStatus.loading) {
          return const Center(child: ProgressRing());
        }
        if (state.invoiceProducts.isEmpty) {
          return const Center(child: Text('No products found for this invoice.'));
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
    );
  }
}

class InvoiceProductSummary extends StatelessWidget {
  const InvoiceProductSummary({super.key});

  @override
  Widget build(BuildContext context) {
    // subtotal, discount, total align right, color: onsurfacevariant
    return BlocBuilder<InvoiceListBloc, InvoiceListState>(
      builder: (context, state) {
        if (state.status == DataStatus.loading) {
          return const Center(child: ProgressRing());
        }
        final invoice = context.read<PaymentFormBloc>().state.invoice!;

        final total = invoice.amountDue;
        final discount = invoice.discountType == DiscountType.percentage
            ? (total * (invoice.discount ?? 0) / 100)
            : invoice.discount;
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
                        style: TextStyles.body.merge(TextStyles.onSurfaceVariant),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        total.toStringAsFixed(2),
                        style: TextStyles.body.merge(TextStyles.strong),
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
