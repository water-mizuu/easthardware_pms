import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:flutter/foundation.dart';

@immutable
class Invoice {
  const Invoice({
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
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    try {
      printBoxed(map);

      // Handle discount_type with proper null checking
      DiscountType? discountType;
      if (map['discount'] != null && map['discount_type'] != null) {
        final discountTypeIndex = map['discount_type'] as int;
        if (discountTypeIndex < DiscountType.values.length) {
          discountType = DiscountType.values[discountTypeIndex];
        }
      }

      // Handle date parsing with proper error handling
      DateTime? paymentDate;
      if (map['payment_date'] != null &&
          map['payment_date'] is String &&
          map['payment_date'].toString().isNotEmpty) {
        try {
          paymentDate = DateTime.parse(map['payment_date']);
        } catch (e) {
          printBoxed("Error parsing payment_date: ${map['payment_date']}, $e", 'Invoice');
        }
      }

      return Invoice(
        id: map['id'] as int?,
        customerName: map['customer_name'] as String? ?? '',
        invoiceDate: DateTime.parse(map['invoice_date'] as String),
        dueDate: DateTime.parse(map['due_date'] as String),
        paymentMethod: map['payment_method'] as int?,
        referenceNumber: map['reference_number'] as String?,
        memo: map['memo'] as String?,
        discount: map['discount'] != null ? (map['discount'] as num).toDouble() : null,
        discountType: discountType,
        creationDate: DateTime.parse(map['creation_date'] as String),
        paymentDate: paymentDate,
        amountDue: (map['amount_due'] as num).toDouble(),
        amountPaid: map['amount_paid'] != null ? (map['amount_paid'] as num).toDouble() : null,
        creatorId: map['creator_id'] as int,
      );
    } catch (e) {
      printBoxed("Error parsing Invoice from map: $e", 'Invoice');
      throw FormatException('Invalid invoice data: $e');
    }
  }
  final int? id;
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
    final map = <String, dynamic>{
      'customer_name': customerName,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'memo': memo,
      'amount_due': amountDue,
      'creator_id': creatorId,
      'creation_date': creationDate.toIso8601String(),
    };

    // Only add optional fields if they are not null
    if (discount != null) {
      map['discount'] = discount;
      // Only include discount_type if discount is present
      if (discountType != null) {
        map['discount_type'] = discountType!.index;
      }
    }

    if (paymentDate != null) {
      map['payment_date'] = paymentDate!.toIso8601String();
    }

    if (amountPaid != null) {
      map['amount_paid'] = amountPaid;
    }

    // Include ID if available (for updates)
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }
}
