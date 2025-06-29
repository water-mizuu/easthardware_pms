import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/domain/repository/order_repository.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_method_list/payment_method_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/models/form_product.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/order/create_restock_order_page/product_name.dart';
import 'package:easthardware_pms/presentation/views/order/create_restock_order_page/quantity_and_unit.dart';
import 'package:easthardware_pms/presentation/views/order/order_widgets/amount.dart';
import 'package:easthardware_pms/presentation/views/order/order_widgets/description.dart';
import 'package:easthardware_pms/presentation/views/order/order_widgets/header.dart';
import 'package:easthardware_pms/presentation/views/order/order_widgets/index.dart';
import 'package:easthardware_pms/presentation/views/order/order_widgets/rate.dart';
import 'package:easthardware_pms/presentation/views/order/order_widgets/remove_button.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/expense_type_combo_box.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/payment_method_combo_box.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_column.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class EditRestockOrderPage extends StatefulWidget {
  const EditRestockOrderPage({required this.order, super.key});

  final Order order;

  @override
  State<EditRestockOrderPage> createState() => _EditRestockOrderPageState();
}

class _EditRestockOrderPageState extends State<EditRestockOrderPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(widget.order.id),
      create: (context) {
        final order = widget.order;
        // Get all order products for this order
        final orderProducts = (context.read<OrderListBloc>().state.allOrderProducts)
            .where((p) => p.orderId == order.id)
            .toList();

        // Get necessary payment method and expense type
        final paymentMethod = (context.read<PaymentMethodListBloc>().state.paymentMethods)
            .firstWhere((p) => p.id == order.paymentMethod);

        final expenseType = (context.read<ExpenseTypeListBloc>().state.expenseTypes)
            .firstWhere((e) => e.id == order.expenseType);

        // First, create the correct FormProduct objects with proper descriptions from order products
        final productItems = orderProducts.map((p) {
          final product = context.read<ProductListBloc>().state.allProducts.firstWhere(
              (prod) => prod.id == p.productId,
              orElse: () => throw Exception('Product not found'));

          // Create FormProduct with correct unit information from the actual product
          return FormProduct(
            productId: p.productId,
            productName: p.productName,
            description: p.description, // Preserve the exact description from the order
            quantity: p.quantity,
            unit: product.mainUnit, // Use the actual unit name from the product
            unitId: p.secondaryUnit,
            conversionFactor: p.conversionFactor,
            rate: p.rate,
            amount: p.amount,
            discountType: DiscountType.value,
          );
        }).toList();

        // Debug log to see what we're loading
        printBoxed('Loading ${productItems.length} products for order ${order.id}',
            'EditRestockOrderPage');
        for (final item in productItems) {
          printBoxed(
              'Product: ${item.productName}, '
                  'description: "${item.description}", '
                  'unit: ${item.unit}, '
                  'quantity: ${item.quantity}',
              'ProductItem');
        }

        // Create the bloc with our properly initialized product items
        final bloc = OrderFormBloc.fromExistingRestockOrder(
          order,
          productItems,
          paymentMethod,
          expenseType,
          orderRepository: RepositoryProvider.of<OrderRepository>(context),
        );

        // Load the order details using our event to ensure complete consistency
        bloc.add(LoadExistingRestockOrderEvent(
          order: order,
          expenseType: expenseType,
          paymentMethod: paymentMethod,
          products: orderProducts,
        ));

        return bloc;
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<OrderFormBloc, OrderFormState>(
            listenWhen: (p, c) =>
                p.status != c.status || //
                p.dialogErrorMessage != c.dialogErrorMessage,
            listener: (context, state) {
              if (state.status == FormStatus.error && state.dialogErrorMessage != null) {
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
              } else if (state.status == FormStatus.submitting) {
                final order = state.copyWith().toOrder();

                // Log the full state before conversion to help debugging
                printBoxed('Current state products before conversion:', 'EditRestockOrder');
                for (final stateProduct in state.products!) {
                  printBoxed(
                      'Product: ${stateProduct.productName}, '
                          'ID: ${stateProduct.productId}, '
                          'Description: "${stateProduct.description}", '
                          'Quantity: ${stateProduct.quantity}, '
                          'Unit: ${stateProduct.unit}',
                      'StateProduct');
                }

                // Map products to order products ensuring descriptions are preserved
                final products = state.products?.map((formProduct) {
                  // Create OrderProduct directly from FormProduct
                  final orderProduct = formProduct.toOrderProduct(order.id ?? 0);

                  // Log the conversion to verify description preservation
                  printBoxed(
                      'Converting: ${formProduct.productName}\n'
                          'FormProduct description: "${formProduct.description}"\n'
                          'OrderProduct description: "${orderProduct.description}"',
                      'ProductConversion');

                  return orderProduct;
                }).toList();

                // Final verification to ensure all descriptions are preserved
                printBoxed('Preparing to submit order update', 'EditRestockOrder');

                // Create a new list with corrected descriptions
                final List<OrderProduct> correctedProducts = [];

                for (int i = 0; i < products!.length; i++) {
                  final product = products[i];
                  final originalProduct = state.products![i];

                  // Check if description was lost in the conversion
                  if (originalProduct.description != null &&
                      originalProduct.description != product.description) {
                    printBoxed(
                        'Description mismatch for ${product.productName}:\n'
                            'Original: "${originalProduct.description}"\n'
                            'New: "${product.description}"',
                        'DescriptionError');

                    // Create a corrected version with the right description
                    final correctedProduct = OrderProduct(
                        id: product.id,
                        orderId: product.orderId,
                        productId: product.productId,
                        productName: product.productName,
                        description: originalProduct.description, // Use the original description
                        quantity: product.quantity,
                        secondaryUnit: product.secondaryUnit,
                        conversionFactor: product.conversionFactor,
                        rate: product.rate,
                        amount: product.amount);

                    correctedProducts.add(correctedProduct);
                    printBoxed('Fixed description to: "${correctedProduct.description}"',
                        'DescriptionFix');
                  } else {
                    // No correction needed
                    correctedProducts.add(product);
                  }

                  print('[EditRestockOrder] Saving product: ${product.productName}, '
                      'description: "${product.description}"');
                }

                // Always proceed with the update using our corrected products
                context
                    .read<OrderListBloc>()
                    .add(UpdateRestockOrderEvent(order, correctedProducts));
              }
            },
          ),
          BlocListener<OrderListBloc, OrderListState>(
              listenWhen: (p, c) => c.status == DataStatus.success,
              listener: (context, state) {
                context.read<ProductListBloc>().add(const LoadAllProductsEvent());
                final userName = context.read<AuthenticationBloc>().state.user!;
                final orderId = context.read<OrderFormBloc>().state.orderId;

                context.read<UserLogListBloc>().add(AddUpdateEvent('Order #$orderId', userName));
                context.read<UserLogListBloc>().add(const LoadUserLogsEvent());

                showNotification(
                  title: "Success",
                  message: "Order #$orderId has been successfully updated.",
                  severity: InfoBarSeverity.success,
                );
                context.navigate(AppRoutes.admin.order);
              }),
        ],
        child: Padding(
          padding: AppPadding.panePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(),
              Spacing.v16,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: const _OrderPageForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderPageForm extends StatefulWidget {
  const _OrderPageForm();

  @override
  State<_OrderPageForm> createState() => _OrderPageFormState();
}

class _OrderPageFormState extends State<_OrderPageForm> {
  late final TextEditingController _payeeNameController;
  late final TextEditingController _referenceNumberController;

  @override
  void initState() {
    super.initState();
    _payeeNameController = TextEditingController();
    _referenceNumberController = TextEditingController();

    // Add listeners for controllers
    _payeeNameController.addListener(() {
      if (context.read<OrderFormBloc>().state.payeeName != _payeeNameController.text) {
        context.read<OrderFormBloc>().add(PayeeNameChangedEvent(_payeeNameController.text));
      }
    });

    _referenceNumberController.addListener(() {
      if (context.read<OrderFormBloc>().state.referenceNumber != _referenceNumberController.text) {
        context
            .read<OrderFormBloc>()
            .add(ReferenceNumberChangedEvent(_referenceNumberController.text));
      }
    });
  }

  @override
  void dispose() {
    _payeeNameController.dispose();
    _referenceNumberController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.watch<OrderFormBloc>().state;

    // Update controllers when the state changes, but avoid infinite loops
    // by checking if values actually differ
    if (_payeeNameController.text != state.payeeName) {
      _payeeNameController.text = state.payeeName;
    }

    if (_referenceNumberController.text != state.referenceNumber) {
      _referenceNumberController.text = state.referenceNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrderFormBloc>().state;

    return AnimatedSingleChildScrollView(
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
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(60),
                        FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9\s\-_]+$')),
                      ],
                      controller: _payeeNameController,
                      onChanged: (value) => context //
                          .read<OrderFormBloc>()
                          .add(PayeeNameChangedEvent(value)),
                    ),
                    if (context.watch<OrderFormBloc>().state.payeeNameErrorMessage != null)
                      Text(
                        context.watch<OrderFormBloc>().state.payeeNameErrorMessage!,
                        style: TextStyles.error,
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
                      value: state.paymentMethod,
                      onPaymentMethodSelected: (PaymentMethod value) {
                        context.read<OrderFormBloc>().add(PaymentMethodChangedEvent(value));
                      },
                    ),
                    if (context.watch<OrderFormBloc>().state.paymentMethodErrorMessage != null)
                      Text(
                        context.watch<OrderFormBloc>().state.paymentMethodErrorMessage!,
                        style: TextStyles.error,
                      ),
                  ],
                ),
              ),
              Spacing.h12,
              const Spacer()
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
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(60),
                        FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9\s\-_]+$')),
                      ],
                      controller: _referenceNumberController,
                      onChanged: (value) =>
                          context.read<OrderFormBloc>().add(ReferenceNumberChangedEvent(value)),
                    ),
                    if (context.watch<OrderFormBloc>().state.referenceNumberErrorMessage != null)
                      Text(
                        context.watch<OrderFormBloc>().state.referenceNumberErrorMessage!,
                        style: TextStyles.error,
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
                      onChanged: (date) =>
                          context.read<OrderFormBloc>().add(OrderDateChangedEvent(date)),
                    ),
                    if (context.watch<OrderFormBloc>().state.orderDateErrorMessage != null)
                      Text(
                        context.watch<OrderFormBloc>().state.orderDateErrorMessage!,
                        style: TextStyles.error,
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
                      disabledPlaceholder: Text(state.expenseType?.name ?? 'Inventory Restock'),
                      isDisabled: true,
                      value: state.expenseType,
                    )
                  ],
                ),
              ),
            ],
          ),
          Spacing.v12,
          const _OrderTableActions(),
          Spacing.v4,
          const _OrderProductDataTable(),
          Spacing.v12,
          const _OrderSummaryAndMemo(),
        ].withSpacing(() => Spacing.v12),
      ),
    );
  }
}

class _OrderSummaryAndMemo extends StatefulWidget {
  const _OrderSummaryAndMemo();

  @override
  State<_OrderSummaryAndMemo> createState() => _OrderSummaryAndMemoState();
}

class _OrderSummaryAndMemoState extends State<_OrderSummaryAndMemo> {
  late final TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController();
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.watch<OrderFormBloc>().state;

    if (_memoController.text != state.memo) {
      _memoController.text = state.memo ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrderFormBloc>().state;
    final bloc = context.read<OrderFormBloc>();
    final total = state.orderType == OrderType.restock
        ? state.products?.fold(0.0, (sum, product) => sum + product.amount)
        : state.orderItems?.fold(0.0, (sum, item) => sum + item.amount);

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
                controller: _memoController,
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
                    const Text(
                      "Total",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormatter.full(total ?? 0.0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
              context.read<OrderFormBloc>().add(const ClearProductsEvent());
            },
          ),
          Spacing.h12,
          TextButtonFilled(
            'Add Product',
            onPressed: () {
              context.read<OrderFormBloc>().add(const ProductAddedEvent());
            },
          ),
          Spacing.h16,
        ],
      ),
    );
  }
}

class _OrderProductDataTable extends StatelessWidget {
  const _OrderProductDataTable();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<OrderFormBloc>().state.products!;
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _RestockOrderFormTableRow(index: index);
          },
        ),
      ],
    );
  }
}

class _RestockOrderFormTableRow extends StatelessWidget {
  const _RestockOrderFormTableRow({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final currentProduct = context.watch<OrderFormBloc>().state.products![index];
    // Debug info to trace product data changes
    final info = [
      'productId: ${currentProduct.productId}',
      'name: ${currentProduct.productName}',
      'description: ${currentProduct.description}',
      'quantity: ${currentProduct.quantity}',
      'unit: ${currentProduct.unit}',
      'rate: ${currentProduct.rate}',
      'amount: ${currentProduct.amount}',
      'error: ${currentProduct.errorMessage}',
    ];
    printBoxed('Restock Order Row $index: ${info.join('\n')}', 'EditRestockOrderRow');

    return InheritedProvider<IndexedProductId>.value(
      /// Instead of "prop drilling", we expose the index and the current product
      ///   as a tuple to the children of this widget.
      /// This allows us to access the index and the current product in the
      ///   children without having to pass them down through the widget tree.
      value: (index, currentProduct.productId),
      child: Container(
        decoration: BoxDecoration(
          color: currentProduct.errorMessage != null
              ? Colors.errorSecondaryColor
              : index % 2 == 0
                  ? const Color(0xFFFAFAFA)
                  : Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[40])),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Index(),
                Expanded(flex: 2, child: ProductName()),
                Expanded(flex: 2, child: Description()),
                Expanded(child: QuantityAndUnit()),
                Expanded(child: Rate()),
                Expanded(child: Amount()),
                RemoveButton(),
              ],
            ),
            if (currentProduct.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
                child: Text(
                  currentProduct.errorMessage!,
                  style: TextStyles.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

typedef IndexedProductId = (int, int?);
