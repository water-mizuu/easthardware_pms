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

  InvoiceFormState copyWith({
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
      invoiceId: invoiceId == undefined ? this.invoiceId : invoiceId as int?,
      customerName: customerName == undefined ? this.customerName : customerName as String,
      invoiceDate: invoiceDate == undefined ? this.invoiceDate : invoiceDate as DateTime,
      dueDate: dueDate == undefined ? this.dueDate : dueDate as DateTime,
      products: products == undefined ? this.products : products as List<FormProduct>,
      memo: memo == undefined ? this.memo : memo as String?,
      subtotal: subtotal == undefined ? this.subtotal : subtotal as double?,
      discount: discount == undefined ? this.discount : discount as double?,
      discountType: discountType == undefined ? this.discountType : discountType as DiscountType?,
      amountDue: amountDue == undefined ? this.amountDue : amountDue as double?,
      amountPaid: amountPaid == undefined ? this.amountPaid : amountPaid as double?,
      paymentDate: paymentDate == undefined ? this.paymentDate : paymentDate as DateTime?,
      paymentMethod:
          paymentMethod == undefined ? this.paymentMethod : paymentMethod as PaymentMethod?,
      referenceNumber:
          referenceNumber == undefined ? this.referenceNumber : referenceNumber as String?,
      creatorId: creatorId == undefined ? this.creatorId : creatorId as int?,
      creationDate: creationDate == undefined ? this.creationDate : creationDate as DateTime?,
      invoiceDateErrorMessage: invoiceDateErrorMessage == undefined
          ? this.invoiceDateErrorMessage
          : invoiceDateErrorMessage as String?,
      dueDateErrorMessage: dueDateErrorMessage == undefined
          ? this.dueDateErrorMessage
          : dueDateErrorMessage as String?,
      discountErrorMessage: discountErrorMessage == undefined
          ? this.discountErrorMessage
          : discountErrorMessage as String?,
      dialogErrorMessage:
          dialogErrorMessage == undefined ? this.dialogErrorMessage : dialogErrorMessage as String?,
      status: status == undefined ? this.status : status as FormStatus,
      action: action == undefined ? this.action : action as InvoicePostAction,
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
