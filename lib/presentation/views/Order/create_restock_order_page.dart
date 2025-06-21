import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart'
    show AccessLevel, DataStatus, FormStatus, OrderType;
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/unit_list/unit_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/'
    'expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_router.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/auto_auto_suggest_box.dart';
import 'package:easthardware_pms/presentation/widgets/expense_type_combo_box.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/payment_method_combo_box.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/decorations.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_cell.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_column.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_form_boxes.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

part 'create_restock_order_page/amount.dart';
part 'create_restock_order_page/description.dart';
part 'create_restock_order_page/header.dart';
part 'create_restock_order_page/index.dart';
part 'create_restock_order_page/product_name.dart';
part 'create_restock_order_page/quantity_and_unit.dart';
part 'create_restock_order_page/rate.dart';
part 'create_restock_order_page/remove_button.dart';

class CreateRestockOrderPage extends StatefulWidget {
  const CreateRestockOrderPage({this.product, super.key});

  final Product? product;

  @override
  State<CreateRestockOrderPage> createState() => _CreateRestockOrderPageState();
}

class _CreateRestockOrderPageState extends State<CreateRestockOrderPage> {
  OverlayEntry? overlayEntry;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(widget.product),
      create: (_) => OrderFormBloc.fromRestockOrder(widget.product),
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
                final order = state.toOrder();
                final products = state.products
                    ?.map((product) => product.toOrderProduct(order.id ?? 0))
                    .toList();

                context.read<OrderListBloc>().add(AddOrderEvent(order, products!));
                context.read<OrderFormBloc>().add(const FormSubmittedEvent());
              }
            },
          ),
          BlocListener<OrderListBloc, OrderListState>(
            listenWhen: (p, c) =>
                p.allOrders.length != c.allOrders.length && //
                c.status == DataStatus.success,
            listener: (context, state) {
              context.read<ProductListBloc>().add(const ReloadAllProductsEvent());
              if (context.read<AuthenticationBloc>().state.user!.accessLevel ==
                  AccessLevel.administrator) {
                context.navigate(AppRoutes.admin.order);
                showNotification.success(
                  title: "Success",
                  message: "Order created successfully.",
                );
              } else {
                showNotification.error(
                  title: "What happened?",
                  message: "A staff created an order.",
                );

                printBoxed(
                  "Somehow, a staff created an order, but this should not happen.",
                  "Create Restock Order Page",
                );
              }
            },
          ),
          BlocListener<OrderFormBloc, OrderFormState>(
            listener: (context, state) {
              final overlay = Overlay.of(overlayWidgetKey.currentContext!);

              if (state.status == FormStatus.submitting) {
                if (overlayEntry == null) {
                  overlayEntry = OverlayEntry(builder: (context) {
                    return Container(
                      color: Colors.black.withOpacity(0.2),
                      child: const Center(child: ProgressRing()),
                    );
                  });
                  overlay.insert(overlayEntry!);
                } else {
                  return;
                }
              } else {
                overlayEntry?.remove();
                overlayEntry = null;
              }
            },
          ),
        ],
        child: Padding(
          padding: AppPadding.panePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
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
      ),
    );
  }
}

class OrderPageForm extends StatelessWidget {
  const OrderPageForm({super.key});

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
                      initialValue: state.payeeName,
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
                      initialValue: state.referenceNumber,
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
              const Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BodyText('Expense Type'),
                    Spacing.v8,
                    ExpenseTypeComboBox(
                      disabledPlaceholder: Text('Inventory Restock'),
                      isDisabled: true,
                      value: null,
                    )
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
                _Index(),
                Expanded(flex: 2, child: _ProductName()),
                Expanded(flex: 2, child: _Description()),
                Expanded(child: _QuantityAndUnit()),
                Expanded(child: _Rate()),
                Expanded(child: _Amount()),
                _RemoveButton()
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
