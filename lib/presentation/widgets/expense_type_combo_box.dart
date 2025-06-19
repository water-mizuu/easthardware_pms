import 'dart:async';

import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/presentation/bloc/order/expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/order/expense_type_form_cubit.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExpenseTypeComboBox extends StatefulWidget {
  const ExpenseTypeComboBox({
    super.key,
    required this.value,
    required this.onExpenseTypeSelected,
  });

  final Function(ExpenseType value) onExpenseTypeSelected;
  final ExpenseType? value;
  @override
  State<ExpenseTypeComboBox> createState() => _ExpenseTypeComboBoxState();
}

class _ExpenseTypeComboBoxState extends State<ExpenseTypeComboBox> {
  late final _flyoutController = FlyoutController();
  @override
  Widget build(BuildContext context) {
    final expenseTypes = context.select((ExpenseTypeListBloc b) => b.state.expenseTypes);
    final comboBoxItems = [
      ComboBoxItem(
        value: null,
        child: FlyoutTarget(
          controller: _flyoutController,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add New Expense Type'),
              Icon(FluentIcons.add, size: 12.0),
            ],
          ),
        ),
      ),
      for (final type in expenseTypes) ...[
        ComboBoxItem(
          value: type,
          child: Text(type.name),
        ),
      ],
    ];
    return BlocProvider(
      create: (context) => ExpenseTypeFormCubit(),
      child: Builder(builder: (context) {
        return ComboBox(
          value: widget.value,
          isExpanded: true,
          placeholder: const Text('Select Expense Type'),
          items: comboBoxItems,
          onChanged: (value) {
            if (value is ExpenseType) {
              widget.onExpenseTypeSelected(value);
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
                        children: [
                          const Text('Add New Expense Type', style: TextStyles.subtitle),
                          const SizedBox(height: 8.0),
                          TextFormBox(
                            placeholder: 'Expense Type Name',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Expense Type name cannot be empty';
                              }
                              if (expenseTypes.any((type) => type.name == value)) {
                                return 'Expense Type already exists';
                              }
                              if (value.length > 50) {
                                return 'Expense Type name cannot exceed 50 characters';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              context.read<ExpenseTypeFormCubit>().onNameChanged(value);
                            },
                          ),
                          Spacing.v16,
                          Row(
                            children: [
                              const Spacer(flex: 2),
                              TextButtonFilled(
                                'Save',
                                onPressed: () {
                                  final value = context.read<ExpenseTypeFormCubit>().state.name;
                                  if (value.isNotEmpty &&
                                      !expenseTypes.any((type) => type.name == value)) {
                                    context
                                        .read<ExpenseTypeListBloc>()
                                        .add(AddExpenseTypeEvent(ExpenseType(name: value)));
                                    Navigator.of(context).pop();
                                  }
                                  ;
                                },
                              )
                            ],
                          )
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
