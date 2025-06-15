import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/product.dart';

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

  FormProduct copyWith({
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
  }) {
    return FormProduct(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitId: unitId ?? this.unitId,
      conversionFactor: conversionFactor ?? this.conversionFactor,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      errorMessage: errorMessage,
    );
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
