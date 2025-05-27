import 'package:easthardware_pms/utils/undefined.dart';
import 'package:uuid/uuid.dart';

class Order {

  Order({
    String? uid,
    this.id,
    required this.payeeName,
    required this.expenseType,
    required this.orderDate,
    required this.paymentMethod,
    required this.referenceNumber,
    this.memo,
    required this.amountDue,
    this.amountPaid,
    this.paymentDate,
    required this.creationDate,
    required this.creatorId,
  }) : uid = uid ?? const Uuid().v4();

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      uid: map['uid'],
      payeeName: map['payee_name'],
      expenseType: map['expense_type'],
      orderDate: DateTime.parse(map['order_date']),
      paymentMethod: map['payment_method'],
      referenceNumber: map['reference_number'],
      memo: map['memo'],
      amountDue: map['amount_due'],
      amountPaid: map['amount_paid'],
      paymentDate: map['payment_date'] != null ? DateTime.parse(map['payment_date']) : null,
      creationDate: DateTime.parse(map['creation_date']),
      creatorId: map['creator_id'],
    );
  }
  final int? id;
  final String uid;
  final String payeeName;
  final int expenseType;
  final DateTime orderDate;
  final int paymentMethod;
  final String? referenceNumber;
  final String? memo;
  final double amountDue;
  final double? amountPaid;
  final DateTime? paymentDate;
  final DateTime creationDate;
  final int creatorId;
  Order Function({
    int? id,
    String uid,
    String payeeName,
    int expenseType,
    DateTime orderDate,
    int paymentMethod,
    String? referenceNumber,
    String? memo,
    double amountDue,
    double? amountPaid,
    DateTime? paymentDate,
    DateTime creationDate,
    int creatorId,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? uid = undefined,
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
    }) {
      return Order(
        id: id.or(this.id),
        uid: uid.or(this.uid),
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
      );
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'payee_name': payeeName,
      'expense_type': expenseType,
      'order_date': orderDate.toIso8601String(),
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'memo': memo,
      'amount_due': amountDue,
      'amount_paid': amountPaid,
      'payment_date': paymentDate?.toIso8601String(),
      'creation_date': creationDate.toIso8601String(),
      'creator_id': creatorId,
    };
  }
}
