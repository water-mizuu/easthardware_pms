import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart' show DataStatus, FormStatus;
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/repository/order_repository.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
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
import 'package:easthardware_pms/presentation/widgets/ui/form_table_column.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class CreateRestockOrderPage extends StatefulWidget {
  const CreateRestockOrderPage({this.product, super.key});

  final Product? product;

  @override
  State<CreateRestockOrderPage> createState() => _CreateRestockOrderPageState();
}

class _CreateRestockOrderPageState extends State<CreateRestockOrderPage> {
  // OverlayEntry? overlayEntry;

  @override
  Never setState(void Function() fn) {
    throw Error();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: UniqueKey(),
      create: (context) => OrderFormBloc.fromRestockOrder(
        widget.product,
        orderRepository: RepositoryProvider.of<OrderRepository>(context),
      ),
      child: MultiBlocListener(
        listeners: [
          BlocListener<OrderFormBloc, OrderFormState>(
            listenWhen: (p, c) =>
                p.status != c.status || p.dialogErrorMessage != c.dialogErrorMessage,
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
                if (kDebugMode) {
                  print(
                      'ID: ${order.id}, Payee: ${order.payeeName}, Expense Type: ${order.expenseType}, '
                      'Payment Method: ${order.paymentMethod}, '
                      'Reference Number: ${order.referenceNumber}, '
                      'Order Date: ${order.orderDate}, Amount Due: ${order.amountDue}, '
                      'Memo: ${order.memo}, Created By: ${order.creatorId}, Creation Date: ${order.creationDate},');
                }
                final products = state.products
                    ?.map((product) => product.toOrderProduct(order.id ?? 0))
                    .toList();

                context.read<OrderListBloc>().add(AddProductOrderEvent(order, products!));
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
                final userName = context.read<AuthenticationBloc>().state.user!;
                final orderId = state.allOrders.last.id;
                context.read<UserLogListBloc>().add(AddCreateEvent('Order #$orderId', userName));
                context.read<UserLogListBloc>().add(const LoadUserLogsEvent());

                showNotification(
                  title: "Success",
                  message: "Order #$orderId has been successfully created.",
                  severity: InfoBarSeverity.success,
                );
                context.navigate(AppRoutes.admin.order);
              }),
          BlocListener<OrderFormBloc, OrderFormState>(
            listener: (context, state) {
              // final overlay = Overlay.of(overlayWidgetKey.currentContext!);
              // if (state.status == FormStatus.submitting) {
              //   if (overlayEntry == null) {
              //     overlayEntry = OverlayEntry(builder: (context) {
              //       return Container(
              //         color: Colors.black.withOpacity(0.2),
              //         child: const Center(child: ProgressRing()),
              //       );
              //     });
              //     overlay.insert(overlayEntry!);
              //   } else {
              //     return;
              //   }
              // } else {
              //   overlayEntry?.remove();
              //   overlayEntry = null;
              // }
            },
          ),
        ],
        child: Padding(
          padding: AppPadding.panePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
    final total = state.products?.fold(0.0, (sum, product) => sum + product.amount);

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
