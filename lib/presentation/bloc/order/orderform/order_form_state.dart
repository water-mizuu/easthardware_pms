part of 'order_form_bloc.dart';

class OrderFormState extends Equatable {
  OrderFormState({
    this.payeeName = '',
    this.expenseType = 0,
    DateTime? orderDate,
    this.paymentMethod = 0,
    this.referenceNumber = '',
    this.memo = '',
    this.amountDue = 0.0,
    this.amountPaid,
    DateTime? paymentDate,
    DateTime? creationDate,
    this.creatorId = 0,
    this.id,
    List<FormProduct>? products,
    this.status = FormStatus.initial,
    this.orderDateErrorMessage,
    this.paymentDateErrorMessage,
  })  : orderDate = orderDate ?? DateTime.now(),
        paymentDate = paymentDate ?? DateTime.now(),
        creationDate = creationDate ?? DateTime.now(),
        products = products ?? [EmptyFormProduct()];

  final String payeeName;
  final int expenseType;
  final DateTime orderDate;
  final int paymentMethod;
  final String referenceNumber;
  final String memo;
  final double amountDue;
  final double? amountPaid;
  final DateTime? paymentDate;
  final DateTime creationDate;
  final int creatorId;
  final int? id;
  final List<FormProduct> products;
  final FormStatus status;
  final String? orderDateErrorMessage;
  final String? paymentDateErrorMessage;

  OrderFormState Function({
    String payeeName,
    int expenseType,
    DateTime orderDate,
    int paymentMethod,
    String referenceNumber,
    String memo,
    double amountDue,
    double? amountPaid,
    DateTime? paymentDate,
    DateTime creationDate,
    int creatorId,
    int? id,
    List<FormProduct> products,
    FormStatus status,
    String? orderDateErrorMessage,
    String? paymentDateErrorMessage,
  }) get copyWith {
    return ({
      Object? payeeName = undefined,
      Object? expenseType = undefined,
      Object? orderDate = undefined,
      Object? paymentMethod = undefined,
      Object? referenceNumber = undefined,
      Object? memo = undefined,
      Object? amountDue = undefined,
      Object? amountPaid = undefined,
      Object? paymentDate = undefined,
      Object? creationDate = undefined,
      Object? creatorId = undefined,
      Object? id = undefined,
      Object? products = undefined,
      Object? status = undefined,
      Object? orderDateErrorMessage = undefined,
      Object? paymentDateErrorMessage = undefined,
    }) {
      return OrderFormState(
        payeeName: payeeName.or(this.payeeName),
        expenseType: expenseType.or(this.expenseType),
        orderDate: orderDate.or(this.orderDate),
        paymentMethod: paymentMethod.or(this.paymentMethod),
        referenceNumber: referenceNumber.or(this.referenceNumber),
        memo: memo.or(this.memo),
        amountDue: amountDue.or(this.amountDue),
        amountPaid: amountPaid.or(this.amountPaid),
        paymentDate: paymentDate.or(this.paymentDate),
        creationDate: creationDate.or(this.creationDate),
        creatorId: creatorId.or(this.creatorId),
        id: id.or(this.id),
        products: products.or(this.products),
        status: status.or(this.status),
        orderDateErrorMessage:
            orderDateErrorMessage.or(this.orderDateErrorMessage),
        paymentDateErrorMessage:
            paymentDateErrorMessage.or(this.paymentDateErrorMessage),
      );
    };
  }

  @override
  List<Object?> get props => [
        payeeName,
        expenseType,
        orderDate,
        paymentMethod,
        referenceNumber,
        memo,
        amountDue,
        amountPaid,
        paymentDate,
        creationDate,
        creatorId,
        id,
        products,
        status,
        orderDateErrorMessage,
        paymentDateErrorMessage,
      ];

  Order toOrder() {
    return Order(
      id: id,
      payeeName: payeeName,
      expenseType: expenseType,
      orderDate: orderDate,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      memo: memo,
      amountDue: amountDue,
      amountPaid: amountPaid,
      paymentDate: paymentDate,
      creationDate: creationDate,
      creatorId: creatorId,
    );
  }
}
