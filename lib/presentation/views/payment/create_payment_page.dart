import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_form_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CreatePaymentPage extends StatelessWidget {
  const CreatePaymentPage({
    super.key,
    required this.invoice,
  });

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentFormBloc(),
      child: Builder(builder: (context) {
        return BlocBuilder<PaymentFormBloc, PaymentFormState>(
          builder: (context, state) {
            context.read<PaymentFormBloc>().add(InvoiceChanged(invoice));
            return const Padding(
              padding: AppPadding.panePadding,
              child: Column(
                children: [
                  PageHeader(),
                  Spacing.v16,
                  PaymentForm(),
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
          ],
        );
      },
    );
  }
}

class PaymentForm extends StatelessWidget {
  const PaymentForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentFormBloc, PaymentFormState>(
      builder: (context, state) {
        final invoice = state.invoice!;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Invoice",
                        style: TextStyles.title,
                      ),
                    ),
                    Text(
                      'Created on:',
                      style: TextStyles.body
                          .merge(TextStyles.onSurfaceVariant)
                          .merge(TextStyles.strong),
                    ),
                    Spacing.h8,
                    Text(
                      DateFormat.yMMMMd().format(
                        invoice.creationDate,
                      ),
                      style: TextStyles.body
                          .merge(TextStyles.onSurfaceVariant)
                          .merge(TextStyles.strong),
                    )
                  ],
                ),
                Spacing.v16,
                Row(
                  children: [
                    Expanded(
                      child: Column(
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
                    Expanded(
                        child: Column(
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
                Spacing.v12,
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[40], width: 1),
                    ),
                  ),
                  child: const SizedBox.shrink(),
                ),
                Spacing.v16,
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Payment Method",
                            style: TextStyles.title.merge(TextStyles.onSurface),
                          ),
                        ],
                      ),
                    ),
                    Spacing.h12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Reference Number",
                            style: TextStyles.title.merge(TextStyles.onSurface),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
