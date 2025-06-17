import 'package:easthardware_pms/utils/undefined.dart';

class Payment {
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      referenceNumber: map['reference_number'] as String,
      paymentMethod: map['payment_method'] as int,
      creatorId: map['creator_id'] as int,
      creationDate: DateTime.parse(map['creation_date'] as String),
    );
  }
  const Payment({
    this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    required this.referenceNumber,
    required this.paymentMethod,
    required this.creatorId,
    required this.creationDate,
  });

  final int? id;
  final int invoiceId;
  final double amount;
  final DateTime paymentDate;
  final String referenceNumber;
  final int paymentMethod;
  final int creatorId;
  final DateTime creationDate;

  Payment Function({
    int? id,
    int invoiceId,
    double amount,
    DateTime paymentDate,
    String referenceNumber,
    int paymentMethod,
    int creatorId,
    DateTime creationDate,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? invoiceId = undefined,
      Object? amount = undefined,
      Object? paymentDate = undefined,
      Object? referenceNumber = undefined,
      Object? paymentMethod = undefined,
      Object? creatorId = undefined,
      Object? creationDate = undefined,
    }) {
      return Payment(
        id: id.or(this.id),
        invoiceId: invoiceId.or(this.invoiceId),
        amount: amount.or(this.amount),
        paymentDate: paymentDate.or(this.paymentDate),
        referenceNumber: referenceNumber.or(this.referenceNumber),
        paymentMethod: paymentMethod.or(this.paymentMethod),
        creatorId: creatorId.or(this.creatorId),
        creationDate: creationDate.or(this.creationDate),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'reference_number': referenceNumber,
      'payment_method': paymentMethod,
      'creator_id': creatorId,
      'creation_date': creationDate.toIso8601String(),
    };
  }
}
