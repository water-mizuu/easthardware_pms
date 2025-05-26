import 'package:easthardware_pms/data/database/tables/invoice_products_table.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/utils/undefined.dart';

class InvoiceProduct {
  final int? id;
  final int invoiceId;
  final int productId;
  final String productName;
  final String? description;
  final double? discount;
  final DiscountType? discountType;
  final double quantity;
  final int? secondaryUnit;
  final double? conversionFactor;
  final double rate;
  final double amount;

  InvoiceProduct({
    this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    this.description,
    this.discount,
    this.discountType,
    required this.quantity,
    this.secondaryUnit,
    this.conversionFactor,
    required this.rate,
    required this.amount,
  });

  InvoiceProduct Function({
    int? id,
    int invoiceId,
    int productId,
    String productName,
    String? description,
    double? discount,
    DiscountType? discountType,
    double quantity,
    int? secondaryUnit,
    double? conversionFactor,
    double rate,
    double amount,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? invoiceId = undefined,
      Object? productId = undefined,
      Object? productName = undefined,
      Object? description = undefined,
      Object? discount = undefined,
      Object? discountType = undefined,
      Object? quantity = undefined,
      Object? secondaryUnit = undefined,
      Object? conversionFactor = undefined,
      Object? rate = undefined,
      Object? amount = undefined,
    }) {
      return InvoiceProduct(
        id: id.or(this.id),
        invoiceId: invoiceId.or(this.invoiceId),
        productId: productId.or(this.productId),
        productName: productName.or(this.productName),
        description: description.or(this.description),
        discount: discount.or(this.discount),
        discountType: discountType.or(this.discountType),
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
      InvoiceProductsTable.INVOICE_PRODUCTS_INVOICE: invoiceId,
      InvoiceProductsTable.INVOICE_PRODUCTS_PRODUCT: productId,
      InvoiceProductsTable.INVOICE_PRODUCTS_NAME: productName,
      InvoiceProductsTable.INVOICE_PRODUCTS_DESCRIPTION: description,
      InvoiceProductsTable.INVOICE_PRODUCTS_DISCOUNT: discount,
      InvoiceProductsTable.INVOICE_PRODUCTS_DISCOUNT_TYPE: discountType?.index,
      InvoiceProductsTable.INVOICE_PRODUCTS_QUANTITY: quantity,
      InvoiceProductsTable.INVOICE_PRODUCTS_SECONDARY_UNIT: secondaryUnit,
      InvoiceProductsTable.INVOICE_PRODUCTS_CONVERSION_FACTOR: conversionFactor,
      InvoiceProductsTable.INVOICE_PRODUCTS_RATE: rate,
      InvoiceProductsTable.INVOICE_PRODUCTS_AMOUNT: amount,
    };
  }

  factory InvoiceProduct.fromMap(Map<String, dynamic> map) {
    return InvoiceProduct(
      id: map[InvoiceProductsTable.INVOICE_PRODUCTS_ID],
      invoiceId: map[InvoiceProductsTable.INVOICE_PRODUCTS_INVOICE],
      productId: map[InvoiceProductsTable.INVOICE_PRODUCTS_PRODUCT],
      productName: map[InvoiceProductsTable.INVOICE_PRODUCTS_NAME],
      description: map[InvoiceProductsTable.INVOICE_PRODUCTS_DESCRIPTION],
      discount: map[InvoiceProductsTable.INVOICE_PRODUCTS_DISCOUNT],
      discountType:
          DiscountType.values[map[InvoiceProductsTable.INVOICE_PRODUCTS_DISCOUNT_TYPE] as int],
      quantity: map[InvoiceProductsTable.INVOICE_PRODUCTS_QUANTITY],
      secondaryUnit: map[InvoiceProductsTable.INVOICE_PRODUCTS_SECONDARY_UNIT],
      conversionFactor: map[InvoiceProductsTable.INVOICE_PRODUCTS_CONVERSION_FACTOR],
      rate: map[InvoiceProductsTable.INVOICE_PRODUCTS_RATE],
      amount: map[InvoiceProductsTable.INVOICE_PRODUCTS_AMOUNT],
    );
  }
}
