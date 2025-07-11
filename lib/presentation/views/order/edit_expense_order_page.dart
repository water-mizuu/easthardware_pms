import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/domain/repository/order_repository.dart';
import 'package:easthardware_pms/presentation/bloc/authentication/'
    'authentication/authentication_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderform/order_form_validator.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/'
    'payment_method_list/payment_method_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/security/user_log_list/user_log_list_bloc.dart';
import 'package:easthardware_pms/presentation/cubit/notifications/cubit/notification_cubit.dart';
import 'package:easthardware_pms/presentation/models/form_order_item.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/order/'
    'create_expense_order_page/item_name.dart';
import 'package:easthardware_pms/presentation/views/order/create_expense_order_page/quantity.dart';
import 'package:easthardware_pms/presentation/views/order/order_widgets/amount.dart';
import 'package:easthardware_pms/presentation/views/order/order_widgets/description.dart';
import 'package:easthardware_pms/presentation/views/order/order_widgets/header.dart';
import 'package:easthardware_pms/presentation/views/order/order_widgets/index.dart';
import 'package:easthardware_pms/presentation/views/order/order_widgets/rate.dart';
import 'package:easthardware_pms/presentation/views/order/order_widgets/remove_button.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/bordered_date_picker.dart';
import 'package:easthardware_pms/presentation/widgets/expense_type_combo_box.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/payment_method_combo_box.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/form_table_column.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class EditExpenseOrderPage extends StatefulWidget {
  const EditExpenseOrderPage({required this.order, super.key});

  final Order order;

  @override
  State<EditExpenseOrderPage> createState() => _EditExpenseOrderPageState();
}

class _EditExpenseOrderPageState extends State<EditExpenseOrderPage> {
  // OverlayEntry? overlayEntry;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: UniqueKey(),
      create: (context) {
        final bloc = OrderFormBloc.fromExistingExpenseOrder(
          widget.order.id,
          orderRepository: RepositoryProvider.of<OrderRepository>(context),
        );

        // Load order details asynchronously using the widget.order that's passed in
        Future.microtask(() async {
          if (!context.mounted) return;
          final orderListBloc = context.read<OrderListBloc>();
          final paymentMethodListBloc = context.read<PaymentMethodListBloc>();
          final expenseTypeListBloc = context.read<ExpenseTypeListBloc>();

          // Get the order items for this order
          final orderItems = orderListBloc.state.allOrderItems
              .where((o) => o.orderId == widget.order.id!)
              .toList();

          // Find the payment method from the payment method ID
          final paymentMethod = paymentMethodListBloc.state.paymentMethods
              .firstWhere((p) => p.id == widget.order.paymentMethod);

          // Find the expense type from the expense type ID
          final expenseType = expenseTypeListBloc.state.expenseTypes.firstWhere((e) =>
              e.id ==
              widget.order
                  .expenseType); // Load the existing order data into the form using the LoadExistingExpenseOrderEvent
          bloc.add(LoadExistingExpenseOrderEvent(
            order: widget.order,
            orderItems: orderItems,
            paymentMethod: paymentMethod,
            expenseType: expenseType,
          ));
        });

        return bloc;
      },
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
                final orderItem = state.orderItems //
                    ?.map((item) => item.toOrderItem(order.id ?? 0))
                    .toList();
                context.read<OrderListBloc>().add(UpdateItemOrderEvent(order, orderItem!));
                context.read<OrderFormBloc>().add(const FormSubmittedEvent());
              }
            },
          ),
          BlocListener<OrderListBloc, OrderListState>(
            listenWhen: (p, c) => c.status == DataStatus.success && p.status != c.status,
            listener: (context, state) {
              final authState = context.read<AuthenticationBloc>().state;
              final userName = context.read<AuthenticationBloc>().state.user!;
              final orderId = widget.order.id!;
              context.read<UserLogListBloc>().add(AddUpdateEvent('Order #$orderId', userName));
              context.read<UserLogListBloc>().add(const LoadUserLogsEvent());
              context.read<NotificationCubit>().addNotification(
                    type: NotificationType.warning,
                    title: 'Notice:',
                    message: 'Order No.$orderId was updated by ${authState.user!.username}.',
                    path: '${AppRoutes.admin.editExpenseOrder.path},$orderId',
                  );
              context.navigate(AppRoutes.admin.order);
            },
          ),
          // BlocListener<OrderFormBloc, OrderFormState>(
          //   listener: (context, state) {
          //     // final overlay = Overlay.of(context);

          //     // if (state.status == FormStatus.submitting) {
          //     //   if (overlayEntry == null) {
          //     //     overlayEntry = OverlayEntry(builder: (context) {
          //     //       return Container(
          //     //         color: Colors.black.withOpacity(0.2),
          //     //         child: const Center(child: ProgressRing()),
          //     //       );
          //     //     });
          //     //     overlay.insert(overlayEntry!);
          //     //   }
          //     // } else {
          //     //   overlayEntry?.remove();
          //     //   overlayEntry = null;
          //     // }
          //   },
          // ),
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

class OrderPageForm extends StatefulWidget with OrderFormValidator {
  const OrderPageForm({super.key});

  @override
  State<OrderPageForm> createState() => _OrderPageFormState();
}

class _OrderPageFormState extends State<OrderPageForm> {
  late final TextEditingController _payeeNameController;
  late final TextEditingController _referenceNumberController;

  @override
  void initState() {
    super.initState();
    _payeeNameController = TextEditingController();
    _referenceNumberController = TextEditingController();
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

    // Update controllers when the state changes
    if (_payeeNameController.text != state.payeeName) {
      _payeeNameController.text = state.payeeName;
    }

    if (_referenceNumberController.text != state.referenceNumber) {
      _referenceNumberController.text = state.referenceNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrderFormBloc>();
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
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^[a-zA-Z0-9\s\-_]+$'),
                          replacementString: bloc.state.payeeName,
                        ),
                      ],
                      controller: _payeeNameController,
                      onChanged: (value) => bloc.add(PayeeNameChangedEvent(value)),
                    ),
                    if (state.payeeNameErrorMessage != null)
                      Text(
                        state.payeeNameErrorMessage!,
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
                        bloc.add(PaymentMethodChangedEvent(value));
                      },
                    ),
                    if (state.paymentMethodErrorMessage != null)
                      Text(
                        state.paymentMethodErrorMessage!,
                        style: TextStyles.error,
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
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(60),
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^[a-zA-Z0-9\s\-_]+$'),
                          replacementString: bloc.state.referenceNumber,
                        ),
                      ],
                      controller: _referenceNumberController,
                      onChanged: (value) => bloc.add(ReferenceNumberChangedEvent(value)),
                    ),
                    if (state.referenceNumberErrorMessage != null)
                      Text(
                        state.referenceNumberErrorMessage!,
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
                    BorderedDatePicker(
                      selected: state.orderDate,
                      onChanged: (date) => bloc.add(OrderDateChangedEvent(date)),
                    ),
                    if (state.orderDateErrorMessage != null)
                      Text(
                        state.orderDateErrorMessage!,
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
                      value: state.expenseType,
                      onExpenseTypeSelected: (value) {
                        bloc.add(ExpenseTypeChangedEvent(value));
                      },
                    ),
                    if (state.expenseTypeErrorMessage != null)
                      Text(
                        state.expenseTypeErrorMessage!,
                        style: TextStyles.error,
                      ),
                  ],
                ),
              ),
            ],
          ),
          Spacing.v12,
          const _OrderTableActions(),
          Spacing.v4,
          const OrderItemDataTable(),
          Spacing.v12,
          const OrderSummaryAndMemo(),
        ].withSpacing(() => Spacing.v12),
      ),
    );
  }
}

class OrderSummaryAndMemo extends StatefulWidget {
  const OrderSummaryAndMemo({super.key});

  @override
  State<OrderSummaryAndMemo> createState() => _OrderSummaryAndMemoState();
}

class _OrderSummaryAndMemoState extends State<OrderSummaryAndMemo> {
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
    final total = state.orderItems
            ?.fold<double>(0.0, (previousValue, element) => previousValue + element.amount) ??
        0.0;

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
                      CurrencyFormatter.full(total),
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
              context.read<OrderFormBloc>().add(const ClearOrderItemsEvent());
            },
          ),
          Spacing.h12,
          TextButtonFilled(
            'Add Item',
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

class OrderItemDataTable extends StatelessWidget {
  const OrderItemDataTable({super.key});

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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orderItems.length,
          itemBuilder: (context, index) {
            return _ExpenseOrderFormTableRow(index: index);
          },
        ),
      ],
    );
  }
}

class _ExpenseOrderFormTableRow extends StatelessWidget {
  const _ExpenseOrderFormTableRow({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final currentOrderItem = context.watch<OrderFormBloc>().state.orderItems![index];
    return InheritedProvider<IndexedOrderItem>.value(
      value: (index, currentOrderItem),
      child: Container(
        decoration: BoxDecoration(
          color: currentOrderItem.errorMessage != null
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
                Expanded(flex: 2, child: ItemName()),
                Expanded(flex: 2, child: Description()),
                Expanded(child: Quantity()),
                Expanded(child: Rate()),
                Expanded(child: Amount()),
                RemoveButton(),
              ],
            ),
            if (currentOrderItem.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
                child: Text(
                  currentOrderItem.errorMessage!,
                  style: TextStyles.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

typedef IndexedOrderItem = (int, FormOrderItem);
