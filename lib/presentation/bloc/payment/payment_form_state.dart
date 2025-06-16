part of 'payment_form_bloc.dart';

class PaymentFormState {
  PaymentFormState({
    this.id,
    this.invoiceId,
    this.paymentMethodId = 0,
    this.paymentMethodName = '',
    this.paymentReference = '',
    this.amount = 0,
    DateTime? paymentDate,
    this.creatorId,
    this.creationDate,
    this.status = FormStatus.initial,
  }) : paymentDate = paymentDate ?? DateTime.now();

  final int? id;
  final int? invoiceId;
  final int paymentMethodId;
  final String paymentMethodName;
  final String paymentReference;
  final double amount;
  final DateTime paymentDate;
  final int? creatorId;
  final DateTime? creationDate;
  final FormStatus status;

  PaymentFormState copyWith({
    Object? id = undefined,
    Object? invoiceId = undefined,
    Object? paymentMethodId = undefined,
    Object? paymentMethodName = undefined,
    Object? paymentReference = undefined,
    Object? amount = undefined,
    Object? paymentDate = undefined,
    Object? creatorId = undefined,
    Object? creationDate = undefined,
    Object? status = undefined,
  }) {
    return PaymentFormState(
      id: id == undefined ? this.id : id as int?,
      invoiceId: invoiceId == undefined ? this.invoiceId : invoiceId as int?,
      paymentMethodId: paymentMethodId == undefined ? this.paymentMethodId : paymentMethodId as int,
      paymentMethodName:
          paymentMethodName == undefined ? this.paymentMethodName : paymentMethodName as String,
      paymentReference:
          paymentReference == undefined ? this.paymentReference : paymentReference as String,
      amount: amount == undefined ? this.amount : amount as double,
      paymentDate: paymentDate == undefined ? this.paymentDate : paymentDate as DateTime?,
      creatorId: creatorId == undefined ? this.creatorId : creatorId as int?,
      creationDate: creationDate == undefined ? this.creationDate : creationDate as DateTime?,
      status: status == undefined ? this.status : status as FormStatus,
    );
  }

  Payment toPayment() {
    return Payment(
      invoiceId: invoiceId!,
      amount: amount,
      paymentDate: paymentDate,
      referenceNumber: paymentReference,
      paymentMethod: paymentMethodId,
      creatorId: creatorId!,
      creationDate: creationDate!,
    );
  }
}
