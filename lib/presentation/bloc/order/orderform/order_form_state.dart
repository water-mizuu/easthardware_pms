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
    this.paymentDate,
    DateTime? creationDate,
    this.creatorId = 0,
    this.products = const [],
  })  : orderDate = orderDate ?? DateTime.now(),
        creationDate = creationDate ?? DateTime.now();

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
  final List<FormProduct> products;

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
    List<FormProduct> products,
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
      Object? products = undefined,
    }) {
      return OrderFormState(
        payeeName: payeeName.or(this.payeeName),
        expenseType: expenseType.or(this.expenseType),
        orderDate: orderDate.or(this.orderDate),
        paymentMethod: paymentMethod.or(this.paymentMethod),
        referenceNumber: referenceNumber.or(this.referenceNumber),
        memo: memo.or(this.memo),
        amountDue: amountDue.or(_calculateAmountDue(products.or(this.products))),
        amountPaid: amountPaid.or(this.amountPaid),
        paymentDate: paymentDate.or(this.paymentDate),
        creationDate: creationDate.or(this.creationDate),
        creatorId: creatorId.or(this.creatorId),
        products: products.or(this.products),
      );
    };
  }

  static double _calculateAmountDue(List<FormProduct> products) {
    return products.fold(0, (sum, p) => sum + p.amount);
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
        products,
      ];
}
