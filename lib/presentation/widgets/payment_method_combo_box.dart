import 'dart:async';

import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_method_list/payment_method_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/payment/payment_method_form/payment_method_form_cubit.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentMethodComboBox extends StatefulWidget {
  const PaymentMethodComboBox({
    super.key,
    required this.value,
    required this.onPaymentMethodSelected,
  });

  final Function(PaymentMethod value) onPaymentMethodSelected;
  final PaymentMethod? value;

  @override
  State<PaymentMethodComboBox> createState() => _PaymentMethodComboBoxState();
}

class _PaymentMethodComboBoxState extends State<PaymentMethodComboBox> {
  late final _flyoutController = FlyoutController();

  @override
  Widget build(BuildContext context) {
    final paymentMethods = context.select((PaymentMethodListBloc b) => b.state.paymentMethods);
    final comboBoxItems = [
      ComboBoxItem(
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
        ),
      ],
    ];

    return BlocProvider(
      create: (context) => PaymentMethodFormCubit(),
      child: Builder(builder: (context) {
        return ComboBox(
          value: widget.value,
          placeholder: const Text('Select Payment Method'),
          items: comboBoxItems,
          onChanged: (value) {
            if (value is PaymentMethod) {
              widget.onPaymentMethodSelected(value);
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
                              if (paymentMethods.any((method) => method.name == value)) {
                                return 'Payment method already exists';
                              }
                              return null;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9\s]+$'))
                            ],
                            onChanged: (value) {
                              context.read<PaymentMethodFormCubit>().onFormNameChanged(value);
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
                                  if (paymentMethods
                                      .map((e) => e.name)
                                      .contains(paymentMethodFormState.name)) {
                                    return;
                                  }
                                  final paymentMethod = paymentMethodFormState.toPaymentMethod();
                                  bloc.add(AddPaymentMethodEvent(paymentMethod));
                                  Navigator.of(flyoutContext).pop();
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
        );
      }),
    );
  }
}
