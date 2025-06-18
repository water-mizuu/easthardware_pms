import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_validator.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_column.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateExpenseOrderPage extends StatelessWidget {
  const CreateExpenseOrderPage({super.key, required this.expenseType});
  final int expenseType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderFormBloc(expenseType: expenseType),
      child: MultiBlocListener(
        listeners: [
          BlocListener<OrderFormBloc, OrderFormState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.dialogErrorMessage != current.dialogErrorMessage,
            listener: (context, state) {
              if (state.status == FormStatus.submitting) {
                final order = state.copyWith().toOrder();
                print('Order ID (Expense): ${order.id}');
                final products =
                    state.products.map((product) => product.toOrderProduct(order.id ?? 0)).toList();
                context.read<OrderListBloc>().add(AddOrderEvent(order, products));
                context.read<OrderFormBloc>().add(FormSubmittedEvent());
              } else if (state.status == FormStatus.success) {
                if (context.read<AuthenticationBloc>().state.user!.accessLevel ==
                    AccessLevel.administrator) {
                  context.navigate(AppRoutes.admin.order);
                } else {
                  //context.navigate(AppRoutes.staff.order);
                }
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
              // Only navigate when we're sure the order has been added
              if (context.read<AuthenticationBloc>().state.user!.accessLevel ==
                  AccessLevel.administrator) {
                context.navigate(AppRoutes.admin.order);
              } else {
                //context.navigate(AppRoutes.staff.order);
              }
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
    final formKey = context.read<OrderFormBloc>().formKey;
    final bloc = context.read<OrderFormBloc>();
    final state = context.watch<OrderFormBloc>().state;

    return Form(
      key: formKey,
      child: SingleChildScrollView(
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
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BodyText('Payee Name'),
                      Spacing.v8,
                      TextFormBox(
                        initialValue: state.payeeName,
                        validator: validatePayeeName,
                        onChanged: (value) => bloc.add(PayeeNameChangedEvent(value)),
                      ),
                      if (state.payeeNameErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            state.payeeNameErrorMessage!,
                            style: TextStyle(color: Colors.red.lightest, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                Spacing.h12,
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BodyText('Expense Type'),
                      Spacing.v8,
                      ComboBox<int>(
                        value: state.expenseType,
                        items: const [
                          ComboBoxItem<int>(value: 1, child: Text('Restock Order')),
                          ComboBoxItem<int>(value: 2, child: Text('Expense Order')),
                        ],
                      ),
                    ],
                  ),
                ),
                Spacing.h12,
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
                        validator: validateReferenceNumber,
                        onChanged: (value) => bloc.add(ReferenceNumberChangedEvent(value)),
                      ),
                      if (state.referenceNumberErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            state.referenceNumberErrorMessage!,
                            style: TextStyle(color: Colors.red.lightest, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                Spacing.h12,
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BodyText('Payment Method'),
                      Spacing.v8,
                      ComboBox<int>(
                        placeholder: const Text('Select Payment Method'),
                        value: state.paymentMethod,
                        items: const [
                          ComboBoxItem<int>(value: 1, child: Text('Cash')),
                          ComboBoxItem<int>(value: 2, child: Text('Installment')),
                          ComboBoxItem<int>(value: 3, child: Text('Card')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            bloc.add(PaymentMethodChangedEvent(value));
                          }
                        },
                      ),
                      if (state.paymentMethodErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            state.paymentMethodErrorMessage!,
                            style: TextStyle(color: Colors.red.lightest, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                Spacing.h12,
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BodyText('Payment Date'),
                      Spacing.v8,
                      DatePicker(
                        selected: state.paymentDate,
                        onChanged: (date) => bloc.add(PaymentDateChangedEvent(date)),
                      ),
                      if (state.paymentDateErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            state.paymentDateErrorMessage!,
                            style: TextStyle(color: Colors.red.lightest, fontSize: 12),
                          ),
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
                        selected: state.orderDate,
                        onChanged: (date) => bloc.add(OrderDateChangedEvent(date)),
                      ),
                      if (state.orderDateErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            state.orderDateErrorMessage!,
                            style: TextStyle(color: Colors.red.lightest, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                Spacing.h12,
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
    final total = state.products
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
              context.read<OrderFormBloc>().add(ClearProductsEvent());
            },
          ),
          Spacing.h12,
          TextButtonFilled(
            'Add Product',
            onPressed: () {
              context.read<OrderFormBloc>().add(ProductAddedEvent());
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
              Expanded(flex: 2, child: FormTableColumn(child: const Text("Product"))),
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
                itemCount: state.products.length,
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
    final initialProduct = context.read<OrderFormBloc>().state.products[widget.index];
    _descriptionController = TextEditingController(text: initialProduct.description ?? '');
    _quantityController = TextEditingController(text: initialProduct.quantity.toString());
    _rateController = TextEditingController(text: initialProduct.rate.toString());
    _amountController = TextEditingController(text: initialProduct.amount.toStringAsFixed(2));

    _descriptionController.addListener(() {
      final bloc = context.read<OrderFormBloc>();
      final currentProduct = bloc.state.products[widget.index];
      final newValue = _descriptionController.text;
      if (currentProduct.description != newValue) {
        bloc.add(ProductUpdatedEvent(
          currentProduct.copyWith(description: newValue),
          widget.index,
        ));
      }
    });

    _quantityController.addListener(() {
      final bloc = context.read<OrderFormBloc>();
      final currentProduct = bloc.state.products[widget.index];
      final newValue = double.tryParse(_quantityController.text) ?? 0;
      if (currentProduct.quantity != newValue) {
        bloc.add(ProductUpdatedEvent(
          currentProduct.copyWith(quantity: newValue, amount: newValue * currentProduct.rate),
          widget.index,
        ));
      }
    });

    _rateController.addListener(() {
      final bloc = context.read<OrderFormBloc>();
      final currentProduct = bloc.state.products[widget.index];
      final newValue = double.tryParse(_rateController.text) ?? 0;
      if (currentProduct.rate != newValue) {
        bloc.add(ProductUpdatedEvent(
          currentProduct.copyWith(rate: newValue, amount: currentProduct.quantity * newValue),
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
        return previous.products != current.products ||
            previous.products[widget.index] != current.products[widget.index];
      },
      builder: (context, state) {
        final bloc = context.read<OrderFormBloc>();
        final currentProduct = state.products[widget.index];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_descriptionController.text != (currentProduct.description ?? '')) {
            _descriptionController.text = currentProduct.description ?? '';
          }
          if (_quantityController.text != (currentProduct.quantity.toString())) {
            _quantityController.text =
                currentProduct.quantity != 0 ? currentProduct.quantity.toString() : '';
          }
          if (_rateController.text != (currentProduct.rate.toString())) {
            _rateController.text = currentProduct.rate != 0 ? currentProduct.rate.toString() : '';
          }
          if (_amountController.text != (currentProduct.amount.toStringAsFixed(2))) {
            _amountController.text =
                currentProduct.amount != 0 ? currentProduct.amount.toStringAsFixed(2) : '';
          }
        });

        return Container(
          decoration: BoxDecoration(
            color: currentProduct.errorMessage != null
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
                        placeholder: 'Enter item name',
                        onChanged: (value) {
                          bloc.add(ProductUpdatedEvent(
                            currentProduct.copyWith(
                              productId: -1 *
                                  DateTime.now()
                                      .millisecond, // Mark as expense item with special ID
                            ),
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
                        placeholder: 'Enter details/specifications',
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
              if (currentProduct.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
                  child: Text(
                    currentProduct.errorMessage!,
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
