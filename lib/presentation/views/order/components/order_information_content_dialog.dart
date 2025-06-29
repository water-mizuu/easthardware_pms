import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/presentation/bloc/order/expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/order/components/print_order.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OrderInformationContentDialog extends StatelessWidget {
  const OrderInformationContentDialog({
    super.key,
    required this.context,
    required this.order,
  });

  final BuildContext context;
  final Order order;

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(minHeight: 600, maxWidth: 1200),
      title: DialogTitle(dialogContext: context, order: order),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OrderInformationDetails(order: order),
            Spacing.v16,
            OrderProductTable(order: order),
            Spacing.v16,
            OrderSummary(order: order),
          ],
        ),
      ),
    );
  }
}

class DialogTitle extends StatelessWidget {
  const DialogTitle({
    super.key,
    required this.dialogContext,
    required this.order,
  });

  final BuildContext dialogContext;
  final Order order;

  @override
  Widget build(BuildContext context) {
    final isRestockOrder = order.expenseType == 1; // Assuming 1 is restock type

    return Row(
      children: [
        Text('Order #${order.id}', style: TextStyles.title),
        const Spacer(),
        Row(
          children: [
            Button(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (isRestockOrder) {
                  context.navigateWithExtra(AppRoutes.admin.editRestockOrder, order);
                } else {
                  context.navigateWithExtra(AppRoutes.admin.editExpenseOrder, order);
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Row(
                  children: [
                    Icon(FluentIcons.edit),
                    Spacing.h12,
                    Text('Edit Order', style: TextStyles.body),
                  ],
                ),
              ),
            ),
            Spacing.h8,
            Button(
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Row(
                  children: [
                    Icon(FluentIcons.print),
                    Spacing.h12,
                    Text('Print Order', style: TextStyles.body),
                  ],
                ),
              ),
              onPressed: () {
                final orderProducts = (context.read<OrderListBloc>().state.allOrderProducts)
                    .where((p) => p.orderId == order.id)
                    .toList();
                final orderItems = (context.read<OrderListBloc>().state.allOrderItems)
                    .where((i) => i.orderId == order.id)
                    .toList();
                final expenseType = (context.read<ExpenseTypeListBloc>().state.expenseTypes)
                    .firstWhere((e) => e.id == order.expenseType);

                Navigator.pop(dialogContext);
                generateOrderPdf(order, expenseType, orderProducts, orderItems);
              },
            ),
            Spacing.h8,
            Button(
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Icon(FluentIcons.chrome_close),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            Spacing.h8,
          ],
        ),
        Spacing.h4,
      ],
    );
  }
}

class OrderInformationDetails extends StatelessWidget {
  const OrderInformationDetails({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    final expenseTypeBloc = context.read<ExpenseTypeListBloc>();
    final expenseType =
        expenseTypeBloc.state.expenseTypes.where((e) => e.id == order.expenseType).firstOrNull;
    final expenseTypeName = expenseType?.name ?? 'Unknown';

    final isRestockOrder = order.expenseType == 1; // Assuming 1 is restock type

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isRestockOrder ? 'Restock Order Information' : 'Expense Order Information',
          style: TextStyles.title,
        ),
        Spacing.v12,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text('Order Date', style: TextStyles.onSurfaceVariant)),
                      const Spacer(),
                      Expanded(
                        child: Text(
                          DateFormat('yyyy-MM-dd').format(order.orderDate),
                          style: TextStyles.body,
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ],
                  ),
                  Spacing.v8,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text('Expense Type', style: TextStyles.onSurfaceVariant)),
                      const Spacer(),
                      Expanded(
                        child: Text(
                          expenseTypeName,
                          style: TextStyles.body,
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ],
                  ),
                  if (order.referenceNumber?.isNotEmpty == true) ...[
                    Spacing.v8,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Text('Reference Number', style: TextStyles.onSurfaceVariant)),
                        const Spacer(),
                        Expanded(
                          child: Text(
                            order.referenceNumber ?? 'N/A',
                            style: TextStyles.body,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text('Payee Name', style: TextStyles.onSurfaceVariant)),
                      const Spacer(),
                      Expanded(
                        child: Text(
                          order.payeeName.isNotEmpty ? order.payeeName : 'Unknown Payee',
                          style: TextStyles.body,
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ],
                  ),
                  Spacing.v8,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text('Payment Method', style: TextStyles.onSurfaceVariant)),
                      const Spacer(),
                      Expanded(
                        child: Text(
                          _getPaymentMethodName(order.paymentMethod),
                          style: TextStyles.body,
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ],
                  ),
                  if (order.memo != null && order.memo!.isNotEmpty) ...[
                    Spacing.v8,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text('Memo', style: TextStyles.onSurfaceVariant)),
                        const Spacer(),
                        Expanded(
                          flex: 3,
                          child: Text(
                            order.memo ?? '',
                            style: TextStyles.body,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        )
      ],
    );
  }

  String _getPaymentMethodName(int paymentMethodId) {
    switch (paymentMethodId) {
      case 1:
        return 'Cash';
      case 2:
        return 'Credit Card';
      case 3:
        return 'Bank Transfer';
      case 4:
        return 'Check';
      default:
        return 'Unknown';
    }
  }
}

class OrderProductTable extends StatefulWidget {
  const OrderProductTable({super.key, required this.order});

  final Order order;

  @override
  State<OrderProductTable> createState() => _OrderProductTableState();
}

class _OrderProductTableState extends State<OrderProductTable> {
  @override
  void initState() {
    super.initState();
    // Load order products when the widget is initialized
    context.read<OrderListBloc>().add(const FetchOrderProductsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrderListBloc>().state;
    if (state.status == DataStatus.loading) {
      return const Center(child: ProgressRing());
    }

    // Check if the order is a restock order
    final isRestockOrder = widget.order.expenseType == 1;

    // Filter order products for this specific order
    final orderProducts = state.allOrderProducts //
        .where((p) => p.orderId == widget.order.id)
        .toList();

    final orderItems = state.allOrderItems //
        .where((i) => i.orderId == widget.order.id)
        .toList();

    if (isRestockOrder && orderProducts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Items', style: TextStyles.title),
          Spacing.v12,
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[40]),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: const Center(child: Text('No products found for this order.')),
          ),
        ],
      );
    }

    if (isRestockOrder) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Items', style: TextStyles.title),
          Spacing.v12,
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[40], width: 1),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 32.0, child: Center(child: Text("#"))),
                Spacing.h16,
                Expanded(
                  flex: 2,
                  child: Text(
                    'PRODUCT',
                    style: TextStyles.body.merge(TextStyles.strong),
                  ),
                ),
                Spacing.h16,
                Expanded(
                  flex: 3,
                  child: Text(
                    'DESCRIPTION',
                    style: TextStyles.body.merge(TextStyles.strong),
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: Text(
                    'QUANTITY',
                    style: TextStyles.body.merge(TextStyles.strong),
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: Text(
                    'UNIT PRICE',
                    style: TextStyles.body.merge(TextStyles.strong),
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: Text(
                    'AMOUNT',
                    style: TextStyles.body.merge(TextStyles.strong),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < orderProducts.length; i++) ...[
            if (i > 0) Spacing.v8,
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                color: i % 2 == 0 ? const Color(0xFFFAFAFA) : null,
                border: Border(bottom: BorderSide(color: Colors.grey[40], width: 1)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 32.0, child: Center(child: Text('${i + 1}'))),
                  Spacing.h16,
                  Expanded(
                    flex: 2,
                    child: Text(
                      orderProducts[i].productName,
                      style: TextStyles.body,
                    ),
                  ),
                  Spacing.h16,
                  Expanded(
                    flex: 3,
                    child: Text(
                      orderProducts[i].description ?? '',
                      style: TextStyles.body,
                    ),
                  ),
                  Spacing.h16,
                  Expanded(
                    child: Text(
                      '${orderProducts[i].quantity} ${orderProducts[i].secondaryUnit ?? ''}',
                      style: TextStyles.body,
                    ),
                  ),
                  Spacing.h16,
                  Expanded(
                    child: Text(
                      CurrencyFormatter.full(orderProducts[i].rate),
                      style: TextStyles.body,
                    ),
                  ),
                  Spacing.h16,
                  Expanded(
                    child: Text(
                      CurrencyFormatter.full(orderProducts[i].amount),
                      style: TextStyles.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    } else {
      // For expense orders, show memo or additional details
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Items', style: TextStyles.title),
          Spacing.v12,
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[40], width: 1),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 32.0, child: Center(child: Text("#"))),
                Spacing.h16,
                Expanded(
                  flex: 2,
                  child: Text(
                    'PRODUCT',
                    style: TextStyles.body.merge(TextStyles.strong),
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: Text(
                    'QUANTITY',
                    style: TextStyles.body.merge(TextStyles.strong),
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: Text(
                    'UNIT PRICE',
                    style: TextStyles.body.merge(TextStyles.strong),
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: Text(
                    'AMOUNT',
                    style: TextStyles.body.merge(TextStyles.strong),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < orderItems.length; i++) ...[
            if (i > 0) Spacing.v8,
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                color: i % 2 == 0 ? const Color(0xFFFAFAFA) : null,
                border: Border(bottom: BorderSide(color: Colors.grey[40], width: 1)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 32.0, child: Center(child: Text('${i + 1}'))),
                  Spacing.h16,
                  Expanded(
                    flex: 2,
                    child: Text(
                      orderItems[i].name,
                      style: TextStyles.body,
                    ),
                  ),
                  Spacing.h16,
                  Expanded(
                    child: Text(
                      '${orderItems[i].quantity}',
                      style: TextStyles.body,
                    ),
                  ),
                  Spacing.h16,
                  Expanded(
                    child: Text(
                      CurrencyFormatter.full(orderItems[i].rate),
                      style: TextStyles.body,
                    ),
                  ),
                  Spacing.h16,
                  Expanded(
                    child: Text(
                      CurrencyFormatter.full(orderItems[i].amount),
                      style: TextStyles.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Spacing.v16,
          const Text('Expense Details', style: TextStyles.title),
          Spacing.v12,
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[40]),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.order.memo != null && widget.order.memo!.isNotEmpty) ...[
                  const Text('Memo:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Spacing.v8,
                  Text(widget.order.memo!),
                ] else ...[
                  const Text('No additional details provided for this expense order.'),
                ],
              ],
            ),
          ),
        ],
      );
    }
  }
}

class OrderSummary extends StatelessWidget {
  const OrderSummary({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderListBloc, OrderListState>(
      builder: (context, state) {
        if (state.status == DataStatus.loading) {
          return const Center(child: ProgressRing());
        }

        final total = order.amountDue;
        final amountPaid = order.amountPaid ?? 0.0;
        final openBalance = total - amountPaid;

        return Row(
          children: [
            const Spacer(flex: 2),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL:',
                        style: TextStyles.body.merge(TextStyles.onSurfaceVariant),
                        textAlign: TextAlign.end,
                      ),
                      Text(
                        CurrencyFormatter.full(total),
                        style: TextStyles.body,
                      ),
                    ],
                  ),
                  Spacing.v8,
                  if (amountPaid > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AMOUNT PAID:',
                          style: TextStyles.body.merge(TextStyles.onSurfaceVariant),
                          textAlign: TextAlign.end,
                        ),
                        Text(
                          CurrencyFormatter.full(amountPaid),
                          style: TextStyles.body,
                        ),
                      ],
                    ),
                    Spacing.v8,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'OPEN BALANCE:',
                          style: TextStyles.title.merge(TextStyles.onSurfaceVariant),
                          textAlign: TextAlign.end,
                        ),
                        Text(
                          CurrencyFormatter.full(openBalance),
                          style: TextStyles.title,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
