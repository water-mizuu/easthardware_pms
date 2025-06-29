import 'package:easthardware_pms/utils/boxed.dart';
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
    try {
      // Handle date parsing with proper error handling
      DateTime? paymentDate;
      if (map['payment_date'] != null &&
          map['payment_date'] is String &&
          map['payment_date'].toString().isNotEmpty) {
        try {
          paymentDate = DateTime.parse(map['payment_date']);
        } catch (e) {
          printBoxed("Error parsing payment_date: ${map['payment_date']}, $e", 'Order');
        }
      }

      return Order(
        id: map['id'] as int?,
        uid: map['uid'] as String? ?? const Uuid().v4(),
        payeeName: map['payee_name'] as String? ?? '',
        expenseType: map['expense_type'] as int,
        orderDate: DateTime.parse(map['order_date'] as String),
        paymentMethod: map['payment_method'] as int,
        referenceNumber: map['reference_number'] as String?,
        memo: map['memo'] as String?,
        amountDue: (map['amount_due'] as num).toDouble(),
        amountPaid: map['amount_paid'] != null ? (map['amount_paid'] as num).toDouble() : null,
        paymentDate: paymentDate,
        creationDate: DateTime.parse(map['creation_date'] as String),
        creatorId: map['creator_id'] as int,
      );
    } catch (e) {
      printBoxed("Error parsing Order from map: $e", 'Order');
      throw FormatException('Invalid order data: $e');
    }
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
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'payee_name': payeeName,
      'expense_type': expenseType,
      'order_date': orderDate.toIso8601String(),
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'memo': memo,
      'amount_due': amountDue,
      'creation_date': creationDate.toIso8601String(),
      'creator_id': creatorId,
      'amount_paid': amountPaid,
      'payment_date': paymentDate?.toIso8601String(),
    };
  }
}
