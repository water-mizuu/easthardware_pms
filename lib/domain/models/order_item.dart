import 'package:easthardware_pms/utils/undefined.dart';

class OrderItem {
  OrderItem({
    this.id,
    required this.orderId,
    required this.name,
    this.description,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      name: map['name'],
      description: map['description'],
      quantity: map['quantity'],
      rate: map['rate'],
      amount: map['amount'],
    );
  }

  final int? id;
  final int orderId;
  final String name;
  final String? description;
  final int quantity;
  final double rate;
  final double amount;

  OrderItem Function({
    int? id,
    int orderId,
    String name,
    String? description,
    int quantity,
    double rate,
    int amount,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? orderId = undefined,
      Object? name = undefined,
      Object? description = undefined,
      Object? quantity = undefined,
      Object? rate = undefined,
      Object? amount = undefined,
    }) {
      return OrderItem(
        id: id.or(this.id),
        orderId: orderId.or(this.orderId),
        name: name.or(this.name),
        description: description.or(this.description),
        quantity: quantity.or(this.quantity),
        rate: rate.or(this.rate),
        amount: amount.or(this.amount),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
    };
  }
}
