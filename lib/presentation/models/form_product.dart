import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/utils/undefined.dart';

class FormProduct {
  factory FormProduct.fromProduct(Product product) {
    return FormProduct(
      productId: product.id,
      productName: product.name,
      description: product.description,
      quantity: 0,
      unit: product.mainUnit,
      conversionFactor: 1,
      rate: product.salePrice,
      amount: 0,
      discountType: DiscountType.value,
    );
  }
  const FormProduct({
    this.productId,
    required this.productName,
    this.description,
    required this.quantity,
    required this.unit,
    this.unitId,
    this.conversionFactor,
    required this.rate,
    required this.amount,
    this.discount,
    required this.discountType,
    this.errorMessage,
  });
  final int? productId;
  final String productName;
  final String? description;
  final double quantity;
  final int? unitId;
  final String unit;
  final double? conversionFactor;
  final double rate;
  final double amount;
  final double? discount;
  final DiscountType discountType;
  final String? errorMessage;

  FormProduct Function({
    int? productId,
    String? productName,
    String? description,
    double? quantity,
    String? unit,
    int? unitId,
    double? conversionFactor,
    double? rate,
    double? amount,
    double? discount,
    DiscountType? discountType,
    String? errorMessage,
  }) get copyWith {
    return ({
      Object? productId = undefined,
      Object? productName = undefined,
      Object? description = undefined,
      Object? quantity = undefined,
      Object? unit = undefined,
      Object? unitId = undefined,
      Object? conversionFactor = undefined,
      Object? rate = undefined,
      Object? amount = undefined,
      Object? discount = undefined,
      Object? discountType = undefined,
      Object? errorMessage = undefined,
    }) {
      return FormProduct(
        productId: productId.or(this.productId),
        productName: productName.or(this.productName),
        description: description.or(this.description),
        quantity: quantity.or(this.quantity),
        unit: unit.or(this.unit),
        unitId: unitId.or(this.unitId),
        conversionFactor: conversionFactor.or(this.conversionFactor),
        rate: rate.or(this.rate),
        amount: amount.or(this.amount),
        discount: discount.or(this.discount),
        discountType: discountType.or(this.discountType),
        errorMessage: errorMessage.or(this.errorMessage),
      );
    };
  }

  InvoiceProduct toInvoiceProduct() {
    return InvoiceProduct(
      productId: productId!,
      productName: productName,
      description: description,
      quantity: quantity,
      secondaryUnit: unitId,
      conversionFactor: conversionFactor,
      rate: rate,
      amount: amount,
    );
  }

  OrderProduct toOrderProduct(int orderId) {
    return OrderProduct(
      orderId: orderId,
      productId: productId!,
      productName: productName,
      description: description,
      quantity: quantity,
      secondaryUnit: unitId,
      conversionFactor: conversionFactor,
      rate: rate,
      amount: amount,
    );
  }
}

class EmptyFormProduct extends FormProduct {
  const EmptyFormProduct()
      : super(
          productName: '',
          quantity: 0,
          unit: '',
          rate: 0,
          amount: 0,
          discountType: DiscountType.value,
        );
}
