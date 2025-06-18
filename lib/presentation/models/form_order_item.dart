import 'package:easthardware_pms/utils/undefined.dart';

class FormOrderItem {
  FormOrderItem({
    this.name,
    this.description,
    this.quantity = 0,
    this.rate = 0,
    this.amount = 0,
    this.errorMessage,
  });

  final String? name;
  final String? description;
  final double quantity;
  final double rate;
  final double amount;
  final String? errorMessage;

  FormOrderItem Function({
    String? name,
    String? description,
    double? quantity,
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
        name: name == undefined ? this.name : name as String?,
        description: description == undefined ? this.description : description as String?,
        quantity: quantity == undefined ? this.quantity : quantity as double,
        rate: rate == undefined ? this.rate : rate as double,
        amount: amount == undefined ? this.amount : amount as double,
        errorMessage: errorMessage == undefined ? this.errorMessage : errorMessage as String?,
      );
    };
  }
}
