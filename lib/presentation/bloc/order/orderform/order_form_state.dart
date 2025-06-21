part of 'order_form_bloc.dart';

class OrderFormState {
  factory OrderFormState.restockOrder(Product? product, int? orderId) {
    return OrderFormState(
      orderType: OrderType.restock,
      orderId: orderId,
      products: [
        if (product == null)
          const EmptyFormProduct() //
        else
          FormProduct.fromProduct(product)
      ],
    );
  }
  factory OrderFormState.expenseOrder(int? orderId) {
    return OrderFormState(
      orderType: OrderType.expense,
      orderId: orderId,
      orderItems: [const FormOrderItem()],
    );
  }
  OrderFormState({
    required this.orderType,
    required this.orderId,
    this.payeeName = '',
    DateTime? orderDate,
    this.paymentMethod,
    this.referenceNumber = '',
    this.expenseType,
    this.memo,
    this.amountDue = 0.0,
    DateTime? paymentDate,
    DateTime? creationDate,
    this.creatorId,
    this.products,
    this.orderItems,
    this.status = FormStatus.initial,
    this.orderDateErrorMessage,
    this.payeeNameErrorMessage,
    this.paymentMethodErrorMessage,
    this.expenseTypeErrorMessage,
    this.referenceNumberErrorMessage,
    this.dialogErrorMessage,
  })  : orderDate = orderDate ?? DateTime.now(),
        creationDate = creationDate ?? DateTime.now();

  // [OrderType] is an enum that defines the type of order (e.g., Restock, Expense)
  final OrderType orderType;
  // [OrderId] is a field that can be used to track the order, which is null if not specified
  final int? orderId;
  // [PayeeName] is the name of the person or entity to whom the order is made
  final String payeeName;
  // [OrderDate] is the date when the order was placed, useful for recording past expenses
  final DateTime orderDate;
  // [ExpenseType] is a late field that specifies the type of expense for expense orders
  final ExpenseType? expenseType;
  // [PaymentMethod] is a late field that specifies how the payment is made (e.g., Cash, Credit Card)
  final PaymentMethod? paymentMethod;
  // [ReferenceNumber] is a field that can be used to track the order or payment
  final String referenceNumber;
  // [Products] is a list of products associated with the order, which is null if the order is an expense order
  final List<FormProduct>? products;
  // [OrderItems] is a list of order items, which is null if the order is a restock order
  final List<FormOrderItem>? orderItems;
  // [Memo] is an optional field for additional notes or comments about the order
  final String? memo;
  // amountDue is the total amount due for the order, which is 0.0 by default
  final double amountDue;
  // [CreationDate] is the date when the order was created, which defaults to the current date
  final DateTime creationDate;
  // [CreatorId] is the ID of the user who created the order, which is null if not specified
  final int? creatorId;
  // [status] is the current status of the form, which defaults to FormStatus.initial
  final FormStatus status;

  final String? payeeNameErrorMessage;
  final String? orderDateErrorMessage;
  final String? paymentMethodErrorMessage;
  final String? expenseTypeErrorMessage;
  final String? referenceNumberErrorMessage;
  final String? dialogErrorMessage;

  OrderFormState Function({
    OrderType? orderType,
    int? orderId,
    String? payeeName,
    DateTime? orderDate,
    PaymentMethod? paymentMethod,
    String? referenceNumber,
    ExpenseType? expenseType,
    String? memo,
    double? amountDue,
    DateTime? creationDate,
    int? creatorId,
    List<FormProduct>? products,
    List<FormOrderItem>? orderItems,
    FormStatus? status,
    String? payeeNameErrorMessage,
    String? orderDateErrorMessage,
    String? paymentMethodErrorMessage,
    String? expenseTypeErrorMessage,
    String? referenceNumberErrorMessage,
    String? dialogErrorMessage,
  }) get copyWith {
    return ({
      Object? orderType = undefined,
      Object? orderId = undefined,
      Object? payeeName = undefined,
      Object? orderDate = undefined,
      Object? paymentMethod = undefined,
      Object? referenceNumber = undefined,
      Object? expenseType = undefined,
      Object? memo = undefined,
      Object? amountDue = undefined,
      Object? creationDate = undefined,
      Object? creatorId = undefined,
      Object? products = undefined,
      Object? orderItems = undefined,
      Object? status = undefined,
      Object? payeeNameErrorMessage = undefined,
      Object? orderDateErrorMessage = undefined,
      Object? paymentMethodErrorMessage = undefined,
      Object? expenseTypeErrorMessage = undefined,
      Object? referenceNumberErrorMessage = undefined,
      Object? dialogErrorMessage = undefined,
    }) {
      return OrderFormState(
        orderType: orderType.or(this.orderType),
        orderId: orderId.or(this.orderId),
        payeeName: payeeName.or(this.payeeName),
        orderDate: orderDate.or(this.orderDate),
        paymentMethod: paymentMethod.or(this.paymentMethod),
        referenceNumber: referenceNumber.or(this.referenceNumber),
        expenseType: expenseType.or(this.expenseType),
        memo: memo.or(this.memo),
        amountDue: amountDue.or(this.amountDue),
        creationDate: creationDate.or(this.creationDate),
        creatorId: creatorId.or(this.creatorId),
        products: products.or(this.products),
        orderItems: orderItems.or(this.orderItems),
        status: status.or(this.status),
        payeeNameErrorMessage: payeeNameErrorMessage.or(this.payeeNameErrorMessage),
        orderDateErrorMessage: orderDateErrorMessage.or(this.orderDateErrorMessage),
        paymentMethodErrorMessage: paymentMethodErrorMessage.or(this.paymentMethodErrorMessage),
        expenseTypeErrorMessage: expenseTypeErrorMessage.or(this.expenseTypeErrorMessage),
        referenceNumberErrorMessage:
            referenceNumberErrorMessage.or(this.referenceNumberErrorMessage),
        dialogErrorMessage: dialogErrorMessage.or(this.dialogErrorMessage),
      );
    };
  }

  Order toOrder() {
    return Order(
      id: orderId,
      payeeName: payeeName,
      expenseType: expenseType!.id!,
      orderDate: orderDate,
      paymentMethod: paymentMethod!.id!,
      referenceNumber: referenceNumber,
      memo: memo,
      amountDue: amountDue,
      creationDate: creationDate,
      creatorId: creatorId!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderType': orderType.name,
      'orderId': orderId,
      'payeeName': payeeName,
      'orderDate': orderDate.toIso8601String(),
      'paymentMethod': paymentMethod?.name,
      'referenceNumber': referenceNumber,
      'expenseType': expenseType?.toMap(),
      'memo': memo,
      'amountDue': amountDue,
      'creationDate': creationDate.toIso8601String(),
      'creatorId': creatorId,
      'products': products?.map((p) => p.toMap()).toList(),
      'orderItems': orderItems?.map((oi) => oi.toMap()).toList(),
    };
  }
}
