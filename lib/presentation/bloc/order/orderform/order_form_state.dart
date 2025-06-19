part of 'order_form_bloc.dart';

class OrderFormState {
  factory OrderFormState.RestockOrder() {
    return OrderFormState(
      orderType: OrderType.restock,
      products: [EmptyFormProduct()],
    );
  }
  factory OrderFormState.ExpenseOrder() {
    return OrderFormState(
      orderType: OrderType.expense,
      orderItems: [FormOrderItem()],
    );
  }
  OrderFormState({
    required this.orderType,
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
    String? payeeName,
    DateTime? orderDate,
    PaymentMethod? paymentMethod,
    String? referenceNumber,
    ExpenseType? expenseType,
    String? memo,
    double? amountDue,
    DateTime? paymentDate,
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
      Object? payeeName = undefined,
      Object? orderDate = undefined,
      Object? paymentMethod = undefined,
      Object? referenceNumber = undefined,
      Object? expenseType = undefined,
      Object? memo = undefined,
      Object? amountDue = undefined,
      Object? paymentDate = undefined,
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
        orderType: orderType == undefined ? this.orderType : orderType as OrderType,
        payeeName: payeeName == undefined ? this.payeeName : payeeName as String,
        orderDate: orderDate == undefined ? this.orderDate : orderDate as DateTime?,
        paymentMethod:
            paymentMethod == undefined ? this.paymentMethod : paymentMethod as PaymentMethod?,
        referenceNumber:
            referenceNumber == undefined ? this.referenceNumber : referenceNumber as String,
        expenseType: expenseType == undefined ? this.expenseType : expenseType as ExpenseType?,
        memo: memo == undefined ? this.memo : memo as String?,
        amountDue: amountDue == undefined ? this.amountDue : amountDue as double,
        creationDate: creationDate == undefined ? this.creationDate : creationDate as DateTime?,
        creatorId: creatorId == undefined ? this.creatorId : creatorId as int?,
        products: products == undefined ? this.products : products as List<FormProduct>?,
        orderItems: orderItems == undefined ? this.orderItems : orderItems as List<FormOrderItem>?,
        status: status == undefined ? this.status : status as FormStatus,
        payeeNameErrorMessage: payeeNameErrorMessage == undefined
            ? this.payeeNameErrorMessage
            : payeeNameErrorMessage as String?,
        orderDateErrorMessage: orderDateErrorMessage == undefined
            ? this.orderDateErrorMessage
            : orderDateErrorMessage as String?,
        paymentMethodErrorMessage: paymentMethodErrorMessage == undefined
            ? this.paymentMethodErrorMessage
            : paymentMethodErrorMessage as String?,
        expenseTypeErrorMessage: expenseType == undefined
            ? this.expenseTypeErrorMessage
            : expenseTypeErrorMessage as String?,
        referenceNumberErrorMessage: referenceNumber == undefined
            ? this.referenceNumberErrorMessage
            : referenceNumberErrorMessage as String?,
        dialogErrorMessage: dialogErrorMessage == undefined
            ? this.dialogErrorMessage
            : dialogErrorMessage as String?,
      );
    };
  }

  Order toOrder() {
    return Order(
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
}
