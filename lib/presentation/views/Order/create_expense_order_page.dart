import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_validator.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/expense_type_combo_box.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/payment_method_combo_box.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_column.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateExpenseOrderPage extends StatelessWidget {
  const CreateExpenseOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderFormBloc.ExpenseOrder(),
      child: MultiBlocListener(
        listeners: [
          BlocListener<OrderFormBloc, OrderFormState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.dialogErrorMessage != current.dialogErrorMessage,
            listener: (context, state) {
              if (state.status == FormStatus.submitting) {
                //   final order = state.copyWith().toOrder();
                //   final products =
                //       state.products.map((product) => product.toOrderProduct(order.id ?? 0)).toList();
                //   context.read<OrderListBloc>().add(AddOrderEvent(order, products));
                //   context.read<OrderFormBloc>().add(FormSubmittedEvent());
                // } else if (state.status == FormStatus.success) {
                //   if (context.read<AuthenticationBloc>().state.user!.accessLevel ==
                //       AccessLevel.administrator) {
                //     context.navigate(AppRoutes.admin.order);
                //   } else {
                //     //context.navigate(AppRoutes.staff.order);
                //   }
              } else if (state.status == FormStatus.error && state.dialogErrorMessage != null) {
                unawaited(showDialog<String>(
                  context: context,
                  builder: (dialogContext) => ContentDialog(
                    title: const Text('Incomplete Details'),
                    content: Text(state.dialogErrorMessage!),
                    actions: [
                      FilledButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                      ),
                    ],
                  ),
                ));
              }
            },
          ),
          BlocListener<OrderListBloc, OrderListState>(
            listenWhen: (previous, current) =>
                current.status == DataStatus.success &&
                current.allOrders.length > previous.allOrders.length,
            listener: (context, state) {
              // // Only navigate when we're sure the order has been added
              // if (context.read<AuthenticationBloc>().state.user!.accessLevel ==
              //     AccessLevel.administrator) {
              //   context.navigate(AppRoutes.admin.order);
              // } else {
              //   //context.navigate(AppRoutes.staff.order);
              // }
            },
          ),
        ],
        child: Stack(
          children: [
            Padding(
              padding: AppPadding.panePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const OrderPageHeader(),
                  Spacing.v16,
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const OrderPageForm(),
                    ),
                  ),
                ],
              ),
            ),
            BlocBuilder<OrderFormBloc, OrderFormState>(
              builder: (context, state) {
                if (state.status == FormStatus.submitting) {
                  return Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                      child: const Center(child: ProgressRing()),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OrderPageHeader extends StatelessWidget {
  const OrderPageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
            icon: const Icon(FluentIcons.back),
            onPressed: () {
              context.navigate(AppRoutes.admin.order);
            }),
        const DisplayText("Create Expense Order"),
        const Spacer(flex: 1),
        TextButtonFilled(
          'Save Order',
          onPressed: () {
            final creationDate = DateTime.now();
            final creatorId = context.read<AuthenticationBloc>().state.user?.id;
            final orderId = context.read<OrderListBloc>().state.allOrders.length;
            context.read<OrderFormBloc>().add(
                  SaveOrderRequestEvent(
                    creationDate: creationDate,
                    creatorId: creatorId!,
                    id: orderId,
                  ),
                );
          },
        ),
        Spacing.h4,
      ].withSpacing(() => Spacing.h16),
    );
  }
}

class OrderPageForm extends StatelessWidget with OrderFormValidator {
  const OrderPageForm({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrderFormBloc>();
    final state = context.watch<OrderFormBloc>().state;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[40], width: 1),
              ),
            ),
            child: Text(
              "Order Information",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[150],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BodyText('Payee Name'),
                    Spacing.v8,
                    TextFormBox(
                      initialValue: state.payeeName,
                      onChanged: (value) => bloc.add(PayeeNameChangedEvent(value)),
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BodyText('Payment Method'),
                    Spacing.v8,
                    PaymentMethodComboBox(
                      value: context.watch<OrderFormBloc>().state.paymentMethod,
                      onPaymentMethodSelected: (PaymentMethod value) {
                        bloc.add(PaymentMethodChangedEvent(value));
                      },
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              const Spacer(),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BodyText('Reference Number'),
                    Spacing.v8,
                    TextFormBox(
                      initialValue: state.referenceNumber,
                      onChanged: (value) => bloc.add(ReferenceNumberChangedEvent(value)),
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BodyText('Order Date'),
                    Spacing.v8,
                    DatePicker(
                      selected: context.watch<OrderFormBloc>().state.orderDate,
                      onChanged: (date) => bloc.add(OrderDateChangedEvent(date)),
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BodyText('Expense Type'),
                    Spacing.v8,
                    ExpenseTypeComboBox(
                        value: state.expenseType,
                        onExpenseTypeSelected: (value) {
                          bloc.add(ExpenseTypeChangedEvent(value));
                        }),
                  ],
                ),
              ),
            ],
          ),
          Spacing.v12,
          const _OrderTableActions(),
          Spacing.v4,
          const OrderProductDataTable(),
          Spacing.v12,
          const _OrderSummaryAndMemo(),
        ].withSpacing(() => Spacing.v12),
      ),
    );
  }
}

class _OrderSummaryAndMemo extends StatelessWidget {
  const _OrderSummaryAndMemo();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrderFormBloc>().state;
    final bloc = context.read<OrderFormBloc>();
    final total = state.orderItems!
        .fold<double>(0.0, (previousValue, element) => previousValue + (element.amount));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BodyText('Memo'),
              Spacing.v8,
              TextBox(
                minLines: 3,
                maxLines: 3,
                onChanged: (value) => bloc.add(MemoChangedEvent(value)),
              ),
            ],
          ),
        ),
        Spacing.h8,
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total"),
                    Text(CurrencyFormatter.full(total),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderTableActions extends StatelessWidget {
  const _OrderTableActions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            "Order Items",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[150],
            ),
          ),
          const Spacer(),
          TextButton(
            'Clear Items',
            onPressed: () {
              context.read<OrderFormBloc>().add(const ClearOrderItemsEvent());
            },
          ),
          Spacing.h12,
          TextButtonFilled(
            'Add Product',
            onPressed: () {
              context.read<OrderFormBloc>().add(const OrderItemAddedEvent());
            },
          ),
          Spacing.h16,
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[40], width: 1)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[150],
        ),
      ),
    );
  }
}

class OrderProductDataTable extends StatelessWidget {
  const OrderProductDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    final orderItems = context.watch<OrderFormBloc>().state.orderItems!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[40])),
          ),
          child: Row(
            children: [
              FormTableColumn(child: const SizedBox(width: 32.0, child: Center(child: Text("#")))),
              Expanded(flex: 2, child: FormTableColumn(child: const Text("Order Item"))),
              Expanded(flex: 2, child: FormTableColumn(child: const Text("Description"))),
              Expanded(child: FormTableColumn(child: const Text("Quantity"))),
              Expanded(child: FormTableColumn(child: const Text("Rate"))),
              Expanded(child: FormTableColumn(child: const Text("Amount"))),
              const SizedBox(width: 82.0, child: Center(child: Text("Actions"))),
            ],
          ),
        ),
        BlocBuilder<OrderFormBloc, OrderFormState>(
            buildWhen: (previous, current) => previous.products != current.products,
            builder: (context, state) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orderItems.length,
                itemBuilder: (context, index) {
                  return _OrderFormTableRow(index: index);
                },
              );
            }),
      ],
    );
  }
}

class _OrderFormTableRow extends StatefulWidget {
  const _OrderFormTableRow({required this.index});
  final int index;

  @override
  State<_OrderFormTableRow> createState() => _OrderFormTableRowState();
}

class _OrderFormTableRowState extends State<_OrderFormTableRow> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _rateController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final initialOrderItem = context.read<OrderFormBloc>().state.orderItems![widget.index];
    _descriptionController = TextEditingController(text: initialOrderItem.description ?? '');
    _quantityController = TextEditingController(text: initialOrderItem.quantity.toString());
    _rateController = TextEditingController(text: initialOrderItem.rate.toString());
    _amountController = TextEditingController(text: initialOrderItem.amount.toString());

    _descriptionController.addListener(() {
      final bloc = context.read<OrderFormBloc>();
      final currentItem = bloc.state.orderItems![widget.index];
      final newValue = _descriptionController.text;
      if (currentItem.description != newValue) {
        bloc.add(OrderItemUpdatedEvent(
          currentItem.copyWith(description: newValue),
          widget.index,
        ));
      }
    });

    _quantityController.addListener(() {
      final bloc = context.read<OrderFormBloc>();
      final currentItem = bloc.state.orderItems![widget.index];
      final newValue = double.tryParse(_quantityController.text) ?? 0;
      if (currentItem.quantity != newValue) {
        bloc.add(OrderItemUpdatedEvent(
          currentItem.copyWith(quantity: newValue, amount: newValue * (currentItem.rate)),
          widget.index,
        ));
      }
    });

    _rateController.addListener(() {
      final bloc = context.read<OrderFormBloc>();
      final currentItem = bloc.state.orderItems![widget.index];
      final newValue = double.tryParse(_rateController.text) ?? 0;
      if (currentItem.rate != newValue) {
        bloc.add(OrderItemUpdatedEvent(
          currentItem.copyWith(rate: newValue, amount: newValue * (currentItem.quantity)),
          widget.index,
        ));
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderFormBloc, OrderFormState>(
      buildWhen: (previous, current) {
        return previous.orderItems != current.orderItems ||
            previous.orderItems![widget.index] != current.orderItems![widget.index];
      },
      builder: (context, state) {
        final bloc = context.read<OrderFormBloc>();
        final currentOrderItem = state.orderItems![widget.index];

        _descriptionController.text = currentOrderItem.description ?? '';
        final newDescription = currentOrderItem.description ?? '';
        final newQuantity = currentOrderItem.quantity % 1 == 0
            ? currentOrderItem.quantity.toInt().toString()
            : currentOrderItem.quantity.toString();

        final newRate = currentOrderItem.rate % 1 == 0
            ? currentOrderItem.rate.toInt().toString()
            : currentOrderItem.rate.toString();

        if (_descriptionController.text != newDescription) {
          _descriptionController.text = newDescription;
        }

        if (_quantityController.text != newQuantity) {
          _quantityController.text = newQuantity;
        }

        if (_rateController.text != newRate) {
          _rateController.text = newRate;
        }

        return Container(
          decoration: BoxDecoration(
            color: currentOrderItem.errorMessage != null
                ? Colors.errorSecondaryColor
                : widget.index % 2 == 0
                    ? const Color(0xFFFAFAFA)
                    : Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[40])),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  FormTableCell(
                    child: SizedBox(
                      width: 32.0,
                      child: Center(child: Text('${widget.index + 1}')),
                    ),
                  ),
                  // Item Name
                  Expanded(
                    flex: 2,
                    child: FormTableCell(
                      child: TextFormBoxes.ghost(
                        placeholder: 'Order Item',
                        onChanged: (value) {
                          bloc.add(OrderItemUpdatedEvent(
                            currentOrderItem,
                            widget.index,
                          ));
                        },
                      ),
                    ),
                  ),
                  // Details/Specs
                  Expanded(
                    flex: 2,
                    child: FormTableCell(
                      child: TextFormBoxes.ghost(
                        controller: _descriptionController,
                        placeholder: 'Description',
                      ),
                    ),
                  ),
                  // Quantity
                  Expanded(
                    child: FormTableCell(
                      child: TextFormBoxes.ghost(
                        controller: _quantityController,
                        placeholder: '0',
                      ),
                    ),
                  ),
                  // Rate
                  Expanded(
                    child: FormTableCell(
                      child: TextFormBoxes.ghost(
                        controller: _rateController,
                        placeholder: '0.00',
                      ),
                    ),
                  ),
                  // Amount - Read only
                  Expanded(
                    child: FormTableCell(
                      child: TextFormBoxes.ghost(
                        controller: _amountController,
                        enabled: false,
                        placeholder: '0.00',
                      ),
                    ),
                  ),
                  widget.index > 0
                      ? SizedBox(
                          width: 82.0,
                          child: Center(
                            child: IconButton(
                              icon: const Icon(FluentIcons.delete),
                              onPressed: () {
                                context
                                    .read<OrderFormBloc>()
                                    .add(ProductRemovedEvent(widget.index));
                              },
                            ),
                          ),
                        )
                      : const SizedBox(width: 82.0)
                ],
              ),
              if (currentOrderItem.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
                  child: Text(
                    currentOrderItem.errorMessage!,
                    style: TextStyle(color: Colors.red.lightest, fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
