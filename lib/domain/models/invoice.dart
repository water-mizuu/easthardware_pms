import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

@immutable
class Invoice {
  Invoice({
    String? uid,
    this.id,
    required this.customerName,
    required this.invoiceDate,
    required this.dueDate,
    this.paymentMethod,
    this.referenceNumber,
    this.memo,
    this.discount,
    this.discountType,
    required this.creationDate,
    this.paymentDate,
    required this.amountDue,
    this.amountPaid,
    required this.creatorId,
  }) : uid = const Uuid().v4();

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      customerName: map['customer_name'],
      invoiceDate: DateTime.parse(map['invoice_date']),
      dueDate: DateTime.parse(map['due_date']),
      paymentMethod: map['payment_method'],
      referenceNumber: map['reference_number'],
      memo: map['memo'],
      discount: map['discount'],
      discountType: DiscountType.values[map['discount_type'] as int],
      creationDate: DateTime.parse(map['creation_date']),
      paymentDate: map['payment_date'] != null ? DateTime.parse(map['payment_date']) : null,
      amountDue: map['amount_due'],
      amountPaid: map['amount_paid'],
      creatorId: map['creator_id'],
    );
  }
  final int? id;
  final String uid;
  final String customerName;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final int? paymentMethod;
  final String? referenceNumber;
  final String? memo;
  final double? discount;
  final DiscountType? discountType;
  final DateTime creationDate;
  final DateTime? paymentDate;
  final double amountDue;
  final double? amountPaid;
  final int creatorId;

  Invoice Function({
    int? id,
    String uid,
    String customerName,
    DateTime invoiceDate,
    DateTime dueDate,
    int paymentMethod,
    String? referenceNumber,
    String? memo,
    double? discount,
    DiscountType? discountType,
    DateTime creationDate,
    DateTime? paymentDate,
    double amountDue,
    double? amountPaid,
    int creatorId,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? uid = undefined,
      Object? customerName = undefined,
      Object? invoiceDate = undefined,
      Object? dueDate = undefined,
      Object? paymentMethod = undefined,
      Object? referenceNumber = undefined,
      Object? memo = undefined,
      Object? discount = undefined,
      Object? discountType = undefined,
      Object? creationDate = undefined,
      Object? paymentDate = undefined,
      Object? amountDue = undefined,
      Object? amountPaid = undefined,
      Object? creatorId = undefined,
    }) {
      return Invoice(
        id: id.or(this.id),
        uid: uid.or(this.uid),
        customerName: customerName.or(this.customerName),
        invoiceDate: invoiceDate.or(this.invoiceDate),
        dueDate: dueDate.or(this.dueDate),
        paymentMethod: paymentMethod.or(this.paymentMethod),
        referenceNumber: referenceNumber.or(this.referenceNumber),
        memo: memo.or(this.memo),
        discount: discount.or(this.discount),
        discountType: discountType.or(this.discountType),
        creationDate: creationDate.or(this.creationDate),
        paymentDate: paymentDate.or(this.paymentDate),
        amountDue: amountDue.or(this.amountDue),
        amountPaid: amountPaid.or(this.amountPaid),
        creatorId: creatorId.or(this.creatorId),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'customer_name': customerName,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'memo': memo,
      'discount': discount,
      'discount_type': discountType?.index,
      'creation_date': creationDate.toIso8601String(),
      'payment_date': paymentDate?.toIso8601String(),
      'amount_due': amountDue,
      'amount_paid': amountPaid,
      'creator_id': creatorId,
    };
  }
}
