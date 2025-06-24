part of 'invoice_form_bloc.dart';

class InvoiceFormState extends Equatable {
  factory InvoiceFormState.fromExistingInvoice(Invoice invoice, List<InvoiceProduct> products) {
    return InvoiceFormState(
      invoiceId: invoice.id,
      customerName: invoice.customerName,
      invoiceDate: invoice.invoiceDate,
      dueDate: invoice.dueDate,
      memo: invoice.memo,
      discount: invoice.discount,
      discountType: invoice.discountType,
      amountDue: invoice.amountDue,
      amountPaid: invoice.amountPaid,
      paymentDate: invoice.paymentDate,
      subtotal: invoice.amountDue + (invoice.discount ?? 0),
      // paymentMethod: invoice.paymentMethod,
      products: [
        if (products.isEmpty)
          const EmptyFormProduct() //
        else
          ...products.map((product) => FormProduct.fromInvoiceProduct(product))
      ],
    );
  }
  InvoiceFormState({
    this.invoiceId,
    this.customerName = '',
    DateTime? invoiceDate,
    DateTime? dueDate,
    this.products = const [EmptyFormProduct()],
    this.memo,
    this.subtotal,
    this.discount,
    this.discountType = DiscountType.value,
    this.amountDue = 0,
    this.amountPaid,
    this.paymentDate,
    this.paymentMethod,
    this.referenceNumber,
    this.creatorId,
    this.creationDate,
    this.invoiceDateErrorMessage,
    this.dueDateErrorMessage,
    this.discountErrorMessage,
    this.dialogErrorMessage,
    this.status = FormStatus.initial,
    this.action = InvoicePostAction.none,
  })  : invoiceDate = invoiceDate ?? DateTime.now(),
        dueDate = dueDate ?? DateTime.now();

  final int? invoiceId;
  final String customerName;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<FormProduct> products;
  final String? memo;
  final double? subtotal;
  final double? discount;
  final DiscountType? discountType;
  final double amountDue;

  // For Payment
  final double? amountPaid;
  final DateTime? paymentDate;
  final PaymentMethod? paymentMethod;
  final String? referenceNumber;

  // For Userlog
  final int? creatorId;
  final DateTime? creationDate;

  // For Form Validation for components with no validator support
  final String? invoiceDateErrorMessage;
  final String? dueDateErrorMessage;
  final String? discountErrorMessage;

  final FormStatus status;
  final String? dialogErrorMessage;
  final InvoicePostAction action;

  InvoiceFormState Function({
    int? invoiceId,
    String customerName,
    DateTime invoiceDate,
    DateTime dueDate,
    List<FormProduct> products,
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
    String? invoiceDateErrorMessage,
    String? dueDateErrorMessage,
    String? discountErrorMessage,
    String? dialogErrorMessage,
    FormStatus status,
    InvoicePostAction action,
  }) get copyWith {
    return ({
      Object? invoiceId = undefined,
      Object? customerName = undefined,
      Object? invoiceDate = undefined,
      Object? dueDate = undefined,
      Object? products = undefined,
      Object? memo = undefined,
      Object? subtotal = undefined,
      Object? discount = undefined,
      Object? discountType = undefined,
      Object? amountDue = undefined,
      Object? amountPaid = undefined,
      Object? paymentDate = undefined,
      Object? paymentMethod = undefined,
      Object? referenceNumber = undefined,
      Object? creatorId = undefined,
      Object? creationDate = undefined,
      Object? invoiceDateErrorMessage = undefined,
      Object? dueDateErrorMessage = undefined,
      Object? discountErrorMessage = undefined,
      Object? dialogErrorMessage = undefined,
      Object? status = undefined,
      Object? action = undefined,
    }) {
      return InvoiceFormState(
        invoiceId: invoiceId.or(this.invoiceId),
        customerName: customerName.or(this.customerName),
        invoiceDate: invoiceDate.or(this.invoiceDate),
        dueDate: dueDate.or(this.dueDate),
        products: products.or(this.products),
        memo: memo.or(this.memo),
        subtotal: subtotal.or(this.subtotal),
        discount: discount.or(this.discount),
        discountType: discountType.or(this.discountType),
        amountDue: amountDue.or(this.amountDue),
        amountPaid: amountPaid.or(this.amountPaid),
        paymentDate: paymentDate.or(this.paymentDate),
        paymentMethod: paymentMethod.or(this.paymentMethod),
        referenceNumber: referenceNumber.or(this.referenceNumber),
        creatorId: creatorId.or(this.creatorId),
        creationDate: creationDate.or(this.creationDate),
        invoiceDateErrorMessage: invoiceDateErrorMessage.or(this.invoiceDateErrorMessage),
        dueDateErrorMessage: dueDateErrorMessage.or(this.dueDateErrorMessage),
        discountErrorMessage: discountErrorMessage.or(this.discountErrorMessage),
        dialogErrorMessage: dialogErrorMessage.or(this.dialogErrorMessage),
        status: status.or(this.status),
        action: action.or(this.action),
      );
    };
  }

  Invoice toInvoice() {
    return Invoice(
      id: invoiceId,
      customerName: customerName,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      paymentMethod: paymentMethod?.id,
      referenceNumber: referenceNumber,
      memo: memo,
      discount: discount,
      discountType: discountType,
      amountDue: amountDue,
      amountPaid: amountPaid,
      creatorId: creatorId!,
      creationDate: creationDate!,
    );
  }

  @override
  List<Object?> get props => [
        invoiceId,
        customerName,
        invoiceDate,
        dueDate,
        products,
        memo,
        subtotal,
        discount,
        discountType,
        amountDue,
        amountPaid,
        paymentDate,
        paymentMethod,
        referenceNumber,
        creatorId,
        creationDate,
        invoiceDateErrorMessage,
        dueDateErrorMessage,
        discountErrorMessage,
        status,
        dialogErrorMessage,
        action,
      ];
}
