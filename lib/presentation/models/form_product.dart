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
  FormProduct({
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
        productId: productId == undefined ? this.productId : productId as int?,
        productName: productName == undefined ? this.productName : productName as String,
        description: description == undefined ? this.description : description as String?,
        quantity: quantity == undefined ? this.quantity : quantity as double,
        unit: unit == undefined ? this.unit : unit as String,
        unitId: unitId == undefined ? this.unitId : unitId as int?,
        conversionFactor:
            conversionFactor == undefined ? this.conversionFactor : conversionFactor as double?,
        rate: rate == undefined ? this.rate : rate as double,
        amount: amount == undefined ? this.amount : amount as double,
        discount: discount == undefined ? this.discount : discount as double?,
        discountType: discountType == undefined ? this.discountType : discountType as DiscountType,
        errorMessage: errorMessage == undefined ? this.errorMessage : errorMessage as String?,
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
  EmptyFormProduct()
      : super(
          productName: '',
          quantity: 0,
          unit: '',
          rate: 0,
          amount: 0,
          discountType: DiscountType.value,
        );
}
