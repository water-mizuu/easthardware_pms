import 'package:easthardware_pms/domain/models/order_item.dart';
import 'package:easthardware_pms/utils/undefined.dart';

class FormOrderItem {
  const FormOrderItem({
    this.name,
    this.description,
    this.quantity = 0,
    this.rate = 0,
    this.amount = 0,
    this.errorMessage,
  });

  final String? name;
  final String? description;
  final int quantity;
  final double rate;
  final double amount;
  final String? errorMessage;

  FormOrderItem Function({
    String? name,
    String? description,
    int? quantity,
    double? rate,
    double? amount,
    String? errorMessage,
  }) get copyWith {
    return ({
      Object? name = undefined,
      Object? description = undefined,
      Object? quantity = undefined,
      Object? rate = undefined,
      Object? amount = undefined,
      Object? errorMessage = undefined,
    }) {
      return FormOrderItem(
        name: name.or(this.name),
        description: description.or(this.description),
        quantity: quantity.or(this.quantity),
        rate: rate.or(this.rate),
        amount: amount.or(this.amount),
        errorMessage: errorMessage.or(this.errorMessage),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'errorMessage': errorMessage,
    };
  }

  OrderItem toOrderItem(int orderId) {
    return OrderItem(
      orderId: orderId,
      name: name ?? '',
      description: description ?? '',
      quantity: quantity,
      rate: rate,
      amount: amount,
    );
  }
}

class EmptyFormOrderItem extends FormOrderItem {
  const EmptyFormOrderItem()
      : super(
          name: '',
          description: '',
          quantity: 0,
          rate: 0,
          amount: 0,
          errorMessage: null,
        );
}
