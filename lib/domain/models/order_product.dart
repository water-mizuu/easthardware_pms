import 'package:easthardware_pms/utils/undefined.dart';

class OrderProduct {
  final int? id;
  final int orderId;
  final int productId;
  final String productName;
  final String? description;
  final double quantity;
  final int? secondaryUnit;
  final double? conversionFactor;
  final double rate;
  final double amount;

  OrderProduct({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.description,
    required this.quantity,
    this.secondaryUnit,
    this.conversionFactor,
    required this.rate,
    required this.amount,
  });

  OrderProduct Function({
    int? id,
    int? orderId,
    int? productId,
    String? productName,
    String? description,
    double? quantity,
    int? secondaryUnit,
    double? conversionFactor,
    double? rate,
    double? amount,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? orderId = undefined,
      Object? productId = undefined,
      Object? productName = undefined,
      Object? description = undefined,
      Object? quantity = undefined,
      Object? secondaryUnit = undefined,
      Object? conversionFactor = undefined,
      Object? rate = undefined,
      Object? amount = undefined,
    }) {
      return OrderProduct(
        id: id.or(this.id),
        orderId: orderId.or(this.orderId),
        productId: productId.or(this.productId),
        productName: productName.or(this.productName),
        description: description.or(this.description),
        quantity: quantity.or(this.quantity),
        secondaryUnit: secondaryUnit.or(this.secondaryUnit),
        conversionFactor: conversionFactor.or(this.conversionFactor),
        rate: rate.or(this.rate),
        amount: amount.or(this.amount),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'description': description,
      'quantity': quantity,
      'secondary_unit': secondaryUnit,
      'conversion_factor': conversionFactor,
      'rate': rate,
      'amount': amount,
    };
  }

  factory OrderProduct.fromMap(Map<String, dynamic> map) {
    return OrderProduct(
      id: map['id'],
      orderId: map['order_id'],
      productId: map['product_id'],
      productName: map['product_name'],
      description: map['description'],
      quantity: map['quantity'],
      secondaryUnit: map['secondary_unit'],
      conversionFactor: map['conversion_factor'],
      rate: map['rate'],
      amount: map['amount'],
    );
  }
}
