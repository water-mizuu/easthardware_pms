part of 'invoice_form_bloc.dart';

class InvoiceFormState extends Equatable {
  final int? invoiceId;
  final String customerName;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<FormProduct> products;
  final String? memo;
  final double? subtotal;
  final double? discount;
  final DiscountType? discountType;
  final double? amountDue;

  // For Payment
  final double? amountPaid;
  final DateTime? paymentDate;
  final PaymentMethod? paymentMethod;
  final String? referenceNumber;

  // For Userlog
  final int? creatorId;
  final DateTime? creationDate;

  InvoiceFormState({
    this.invoiceId,
    this.customerName = '',
    DateTime? invoiceDate,
    DateTime? dueDate,
    List<FormProduct>? products,
    this.memo,
    this.subtotal,
    this.discount,
    this.discountType = DiscountType.value,
    this.amountDue,
    this.amountPaid,
    this.paymentDate,
    this.paymentMethod,
    this.referenceNumber,
    this.creatorId,
    this.creationDate,
  })  : invoiceDate = invoiceDate ?? DateTime.now(),
        products = products ?? [EmptyFormProduct()],
        dueDate = dueDate ?? DateTime.now().add(const Duration(days: 30));

  InvoiceFormState copyWith({
    int? invoiceId,
    String? customerName,
    DateTime? invoiceDate,
    DateTime? dueDate,
    List<FormProduct>? products,
    String? memo,
    double? subtotal,
    double? discount,
    DiscountType? discountType,
    double? amountDue,
    double? amountPaid,
    DateTime? paymentDate,
    PaymentMethod? paymentMethod,
    String? referenceNumber,
    int? creatorId,
    DateTime? creationDate,
  }) {
    return InvoiceFormState(
      invoiceId: invoiceId ?? this.invoiceId,
      customerName: customerName ?? this.customerName,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      products: products ?? this.products,
      memo: memo ?? this.memo,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      amountDue: amountDue ?? this.amountDue,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      creatorId: creatorId ?? this.creatorId,
      creationDate: creationDate ?? this.creationDate,
    );
  }

  @override
  List<Object> get props => [
        invoiceId ?? 0,
        customerName,
        invoiceDate,
        dueDate,
        products,
        memo ?? '',
        subtotal ?? 0.0,
        discount ?? 0.0,
        discountType ?? DiscountType.value,
        amountDue ?? 0.0,
        amountPaid ?? 0.0,
        paymentDate ?? DateTime.now(),
        paymentMethod ?? PaymentMethod.cash,
        referenceNumber ?? '',
        creatorId ?? 0,
        creationDate ?? DateTime.now(),
      ];
}
