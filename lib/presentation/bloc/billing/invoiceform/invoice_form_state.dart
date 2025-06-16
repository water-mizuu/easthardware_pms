part of 'invoice_form_bloc.dart';

class InvoiceFormState extends Equatable {
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
    this.invoiceDateErrorMessage,
    this.dueDateErrorMessage,
    this.discountErrorMessage,
    this.dialogErrorMessage,
    this.status = FormStatus.initial,
    this.action = InvoicePostAction.none,
  })  : invoiceDate = invoiceDate ?? DateTime.now(),
        products = products ?? [EmptyFormProduct()],
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
  final double? amountDue;

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

  static const unchanged = Object();

  InvoiceFormState copyWith({
    Object? invoiceId = unchanged,
    Object? customerName = unchanged,
    Object? invoiceDate = unchanged,
    Object? dueDate = unchanged,
    Object? products = unchanged,
    Object? memo = unchanged,
    Object? subtotal = unchanged,
    Object? discount = unchanged,
    Object? discountType = unchanged,
    Object? amountDue = unchanged,
    Object? amountPaid = unchanged,
    Object? paymentDate = unchanged,
    Object? paymentMethod = unchanged,
    Object? referenceNumber = unchanged,
    Object? creatorId = unchanged,
    Object? creationDate = unchanged,
    Object? invoiceDateErrorMessage = unchanged,
    Object? dueDateErrorMessage = unchanged,
    Object? discountErrorMessage = unchanged,
    Object? dialogErrorMessage = unchanged,
    Object? status = unchanged,
    Object? action = unchanged,
  }) {
    return InvoiceFormState(
      invoiceId: invoiceId == unchanged ? this.invoiceId : invoiceId as int?,
      customerName: customerName == unchanged ? this.customerName : customerName as String,
      invoiceDate: invoiceDate == unchanged ? this.invoiceDate : invoiceDate as DateTime,
      dueDate: dueDate == unchanged ? this.dueDate : dueDate as DateTime,
      products: products == unchanged ? this.products : products as List<FormProduct>,
      memo: memo == unchanged ? this.memo : memo as String?,
      subtotal: subtotal == unchanged ? this.subtotal : subtotal as double?,
      discount: discount == unchanged ? this.discount : discount as double?,
      discountType: discountType == unchanged ? this.discountType : discountType as DiscountType?,
      amountDue: amountDue == unchanged ? this.amountDue : amountDue as double?,
      amountPaid: amountPaid == unchanged ? this.amountPaid : amountPaid as double?,
      paymentDate: paymentDate == unchanged ? this.paymentDate : paymentDate as DateTime?,
      paymentMethod:
          paymentMethod == unchanged ? this.paymentMethod : paymentMethod as PaymentMethod?,
      referenceNumber:
          referenceNumber == unchanged ? this.referenceNumber : referenceNumber as String?,
      creatorId: creatorId == unchanged ? this.creatorId : creatorId as int?,
      creationDate: creationDate == unchanged ? this.creationDate : creationDate as DateTime?,
      invoiceDateErrorMessage: invoiceDateErrorMessage == unchanged
          ? this.invoiceDateErrorMessage
          : invoiceDateErrorMessage as String?,
      dueDateErrorMessage: dueDateErrorMessage == unchanged
          ? this.dueDateErrorMessage
          : dueDateErrorMessage as String?,
      discountErrorMessage: discountErrorMessage == unchanged
          ? this.discountErrorMessage
          : discountErrorMessage as String?,
      dialogErrorMessage:
          dialogErrorMessage == unchanged ? this.dialogErrorMessage : dialogErrorMessage as String?,
      status: status == unchanged ? this.status : status as FormStatus,
      action: action == unchanged ? this.action : action as InvoicePostAction,
    );
  }

  Invoice toInvoice() {
    return Invoice(
      id: invoiceId,
      customerName: customerName,
      invoiceDate: invoiceDate,
      dueDate: dueDate,
      paymentMethod: paymentMethod?.index,
      referenceNumber: referenceNumber,
      memo: memo,
      discount: discount,
      discountType: discountType,
      amountDue: amountDue!,
      amountPaid: amountPaid,
      creatorId: creatorId!,
      creationDate: creationDate!,
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
        subtotal ?? 0,
        discount ?? 0,
        discountType ?? DiscountType.value,
        amountDue ?? 0,
        amountPaid ?? 0,
        paymentDate ?? DateTime.now(),
        paymentMethod ?? PaymentMethod.cash,
        referenceNumber ?? '',
        creatorId ?? 0,
        creationDate ?? DateTime.now(),
        action,
      ];
}
