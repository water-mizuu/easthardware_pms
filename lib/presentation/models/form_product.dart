import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart';

class FormProduct with EquatableMixin {
  factory FormProduct.fromProduct(Product product) {
    return FormProduct(
      productId: product.id,
      productName: product.name,
      description: product.description,
      quantity: 0,
      unit: product.mainUnit,
      conversionFactor: null,
      rate: product.salePrice,
      amount: 0,
      discountType: DiscountType.value,
    );
  }
  factory FormProduct.fromInvoiceProduct(InvoiceProduct invoiceProduct) {
    // We store the unit ID and rely on the UI to map this to an actual unit name
    // The unit field will be properly displayed in the UI by looking up the name
    // based on the unitId or falling back to the product's main unit
    return FormProduct(
      productId: invoiceProduct.productId,
      productName: invoiceProduct.productName,
      description: invoiceProduct.description,
      quantity: invoiceProduct.quantity,
      unit: invoiceProduct.secondaryUnit?.toString() ?? '0', // Will be resolved in UI
      unitId: invoiceProduct.secondaryUnit,
      conversionFactor: invoiceProduct.conversionFactor,
      rate: invoiceProduct.rate,
      amount: invoiceProduct.amount,
      discountType: DiscountType.value,
    );
  }
  factory FormProduct.fromOrderProduct(OrderProduct orderProduct) {
    return FormProduct(
      productId: orderProduct.productId,
      productName: orderProduct.productName,
      description: orderProduct.description,
      quantity: orderProduct.quantity,
      unit: orderProduct.secondaryUnit?.toString() ?? '',
      unitId: orderProduct.secondaryUnit,
      conversionFactor: orderProduct.conversionFactor,
      rate: orderProduct.rate,
      amount: orderProduct.amount,
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
  final int quantity;
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
    String productName,
    String? description,
    int quantity,
    int? unitId,
    String unit,
    double? conversionFactor,
    double rate,
    double amount,
    double? discount,
    DiscountType discountType,
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

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'description': description,
      'quantity': quantity,
      'unitId': unitId,
      'unit': unit,
      'conversionFactor': conversionFactor,
      'rate': rate,
      'amount': amount,
      'discount': discount,
      'discountType': discountType.name,
    };
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        description,
        quantity,
        unitId,
        unit,
        conversionFactor,
        rate,
        amount,
        discount,
        discountType,
        errorMessage,
      ];
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
