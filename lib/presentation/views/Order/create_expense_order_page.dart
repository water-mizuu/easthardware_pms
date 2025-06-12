import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_validator.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_column.dart';

class CreateExpenseOrderPage extends StatelessWidget {
  const CreateExpenseOrderPage({super.key, required this.expenseType});
  final int expenseType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderFormBloc(expenseType: expenseType)
        ..add(ProductAddedEvent()), // Add a product row on creation
      child: BlocListener<OrderFormBloc, OrderFormState>(
        listener: (context, state) {
          // TODO: Add listener logic
        },
        child: Container(
          color: Colors.white,
          padding: AppPadding.panePadding,
          child: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OrderPageHeader(),
                Spacing.v4,
                OrderPageForm(),
                Spacing.v64,
                OrderSummary(),
              ],
            ),
          ),
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
        TextButtonFilled('Save Order', onPressed: () {}),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Spacing.v8,
          const SectionHeader("Order Information"),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BodyText('Payee Name *'),
                    Spacing.v8,
                    TextFormBox(
                      initialValue: state.payeeName,
                      validator: validatePayeeName,
                      onChanged: (value) =>
                          bloc.add(PayeeNameChangedEvent(value)),
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
                    const BodyText('Expense Type *'),
                    Spacing.v8,
                    ComboBox<int>(
                      value: state.expenseType,
                      items: const [
                        ComboBoxItem<int>(
                            value: 1, child: Text('Restock Order')),
                        ComboBoxItem<int>(
                            value: 2, child: Text('Expense Order')),
                      ],
                    ),
                  ],
                ),
              ),
              Spacing.h16,
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
                      onChanged: (value) =>
                          bloc.add(ReferenceNumberChangedEvent(value)),
                    ),
                  ],
                ),
              ),
              Spacing.h16,
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BodyText('Payment Method *'),
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
                  ],
                ),
              ),
              Spacing.h16,
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
                      onChanged: (date) =>
                          bloc.add(PaymentDateChangedEvent(date)),
                    ),
                  ],
                ),
              ),
              Spacing.h16,
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BodyText('Order Date *'),
                    Spacing.v8,
                    DatePicker(
                      selected: state.orderDate,
                      onChanged: (date) =>
                          bloc.add(OrderDateChangedEvent(date)),
                    ),
                  ],
                ),
              ),
              Spacing.h16,
            ],
          ),
          Row(
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
              Spacing.h16,
            ],
          ),
          const _OrderTableActions(),
          const OrderProductDataTable(),
        ].withSpacing(() => Spacing.v16),
      ),
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
    final bloc = context.read<OrderFormBloc>();
    return BlocBuilder<OrderFormBloc, OrderFormState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[40])),
              ),
              child: Row(
                children: [
                  FormTableColumn(
                      child: const SizedBox(
                          width: 32.0, child: Center(child: Text("#")))),
                  Expanded(
                      flex: 2,
                      child: FormTableColumn(child: const Text("Product"))),
                  Expanded(
                      flex: 2,
                      child: FormTableColumn(child: const Text("Description"))),
                  Expanded(
                      child: FormTableColumn(child: const Text("Quantity"))),
                  Expanded(child: FormTableColumn(child: const Text("Rate"))),
                  Expanded(child: FormTableColumn(child: const Text("Amount"))),
                  const SizedBox(
                      width: 82.0, child: Center(child: Text("Actions"))),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bloc.state.products.length,
              itemBuilder: (context, index) {
                return _OrderFormTableRow(index: index);
              },
            ),
          ],
        );
      },
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
  TextEditingController? _descriptionController;
  TextEditingController? _quantityController;
  TextEditingController? _rateController;
  TextEditingController? _amountController;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<OrderFormBloc>();
    final currentProduct = bloc.state.products[widget.index];
    _descriptionController =
        TextEditingController(text: currentProduct.description ?? '');
    _quantityController =
        TextEditingController(text: currentProduct.quantity.toString());
    _rateController =
        TextEditingController(text: currentProduct.rate.toString());
    _amountController =
        TextEditingController(text: currentProduct.amount.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(covariant _OrderFormTableRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bloc = context.read<OrderFormBloc>();
    final currentProduct = bloc.state.products[widget.index];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_descriptionController != null &&
          _descriptionController!.text != (currentProduct.description ?? '')) {
        _descriptionController!.text = currentProduct.description ?? '';
      }
      if (_quantityController != null &&
          _quantityController!.text != currentProduct.quantity.toString()) {
        _quantityController!.text = currentProduct.quantity.toString();
      }
      if (_rateController != null &&
          _rateController!.text != currentProduct.rate.toString()) {
        _rateController!.text = currentProduct.rate.toString();
      }
      if (_amountController != null &&
          _amountController!.text != currentProduct.amount.toStringAsFixed(2)) {
        _amountController!.text = currentProduct.amount.toStringAsFixed(2);
      }
    });
  }

  @override
  void dispose() {
    _descriptionController?.dispose();
    _quantityController?.dispose();
    _rateController?.dispose();
    _amountController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrderFormBloc>();
    final products = context.read<ProductListBloc>().state.allProducts;
    final currentProduct = bloc.state.products[widget.index];
    final units = [
      Unit(name: currentProduct.unit, mainQuantity: 1, unitQuantity: 1),
      ...context
          .read<UnitListBloc>()
          .state
          .units
          .where((u) => u.productId == currentProduct.productId)
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[40])),
      ),
      child: Row(
        children: [
          FormTableCell(
              child: SizedBox(
                  height: 32.0,
                  width: 32.0,
                  child: Center(child: Text((widget.index + 1).toString())))),
          // Product
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                  border: Border(
                      right:
                          BorderSide(width: 0.5, color: Colors.transparent))),
              child: TextFormBox(
                enabled: true,
                placeholder: 'Enter Product Name',
                onChanged: (value) {
                  bloc.add(ProductUpdatedEvent(
                    currentProduct.copyWith(productName: value),
                    widget.index,
                  ));
                },
              ),
            ),
          ),
          // Description
          Expanded(
            flex: 2,
            child: FormTableCell(
              child: TextFormBox(
                controller: _descriptionController,
                enabled: true,
                placeholder: 'Sale Description',
                onChanged: (value) {
                  bloc.add(ProductUpdatedEvent(
                    currentProduct.copyWith(description: value),
                    widget.index,
                  ));
                },
              ),
            ),
          ),
          // Quantity + Unit
          Expanded(
            child: FormTableCell(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormBox(
                        controller: _quantityController,
                        placeholder: '0',
                        onChanged: (value) {
                          final quantity = double.tryParse(value) ?? 0.0;
                          bloc.add(ProductUpdatedEvent(
                            currentProduct.copyWith(
                              quantity: quantity,
                              amount: quantity * currentProduct.rate,
                            ),
                            widget.index,
                          ));
                        },
                      ),
                    ),
                    if (currentProduct.productId != null)
                      Expanded(
                        flex: 2,
                        child: DropDownButton(
                          items: [
                            MenuFlyoutItem(
                                text: Text(products
                                    .firstWhere(
                                        (p) => p.id == currentProduct.productId)
                                    .mainUnit),
                                onPressed: () {
                                  bloc.add(ProductUpdatedEvent(
                                    currentProduct.copyWith(
                                        unit: products
                                            .firstWhere((p) =>
                                                p.id ==
                                                currentProduct.productId)
                                            .mainUnit),
                                    widget.index,
                                  ));
                                }),
                            for (final unit in units)
                              MenuFlyoutItem(
                                text: Text(unit.name),
                                onPressed: () {
                                  bloc.add(ProductUpdatedEvent(
                                    currentProduct.copyWith(unit: unit.name),
                                    widget.index,
                                  ));
                                },
                              ),
                          ],
                          buttonBuilder: (context, onOpen) {
                            return Button(
                                style: ButtonStyle(
                                  padding: const WidgetStatePropertyAll(
                                    EdgeInsetsDirectional.fromSTEB(0, 5, 0, 6),
                                  ),
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Colors.transparent),
                                    ),
                                  ),
                                ),
                                onPressed: onOpen,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(currentProduct.unit),
                                    Spacing.h12,
                                    const Icon(FluentIcons.chevron_down),
                                  ],
                                ));
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Rate
          Expanded(
            child: FormTableCell(
              child: TextFormBox(
                controller: _rateController,
                enabled: true,
                placeholder: '0.0',
                onChanged: (value) {
                  final rate = double.tryParse(value) ?? 0.0;
                  bloc.add(ProductUpdatedEvent(
                    currentProduct.copyWith(rate: rate),
                    widget.index,
                  ));
                },
              ),
            ),
          ),
          // Amount
          Expanded(
            child: FormTableCell(
              child: TextFormBox(
                enabled: false, // Make it read-only
                controller: (_amountController ??= TextEditingController())
                  ..text = (currentProduct.quantity * currentProduct.rate)
                      .toStringAsFixed(2),
                placeholder: (currentProduct.quantity * currentProduct.rate)
                    .toStringAsFixed(2),
              ),
            ),
          ),
          widget.index > 0
              ? SizedBox(
                  width: 82.0,
                  child: Center(
                    child: IconButton(
                        icon: const Icon(FluentIcons.cancel),
                        onPressed: () =>
                            bloc.add(ProductRemovedEvent(widget.index))),
                  ),
                )
              : const SizedBox(width: 82.0)
        ],
      ),
    );
  }
}

class OrderSummary extends StatelessWidget {
  const OrderSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderFormBloc, OrderFormState>(
        builder: (context, state) {
      final total = state.products.fold<double>(
          0.0, (previousValue, element) => previousValue + (element.amount));
      return Row(
        children: [
          const Spacer(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Php. ${total.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
