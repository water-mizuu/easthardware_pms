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

  OrderFormState copyWith({
    String? payeeName,
    int? expenseType,
    DateTime? orderDate,
    int? paymentMethod,
    String? referenceNumber,
    String? memo,
    double? amountDue,
    double? amountPaid,
    DateTime? paymentDate,
    DateTime? creationDate,
    int? creatorId,
    List<FormProduct>? products,
  }) {
    return OrderFormState(
      payeeName: payeeName ?? this.payeeName,
      expenseType: expenseType ?? this.expenseType,
      orderDate: orderDate ?? this.orderDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      memo: memo ?? this.memo,
      amountDue: amountDue ?? _calculateAmountDue(products ?? this.products),
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      creationDate: creationDate ?? this.creationDate,
      creatorId: creatorId ?? this.creatorId,
      products: products ?? this.products,
    );
  }

  static double _calculateAmountDue(List<FormProduct> products) {
    return products.fold(
      0,
      (sum, p) => sum + (p.amount ?? 0),
    );
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
