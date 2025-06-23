part of 'payment_form_bloc.dart';

class PaymentFormState {
  PaymentFormState({
    this.id,
    this.invoice,
    this.paymentMethod,
    this.paymentReference = '',
    this.amount = 0,
    DateTime? paymentDate,
    this.creatorId,
    this.creationDate,
    this.status = FormStatus.initial,
    this.paymentMethodError,
    this.referenceNumberError,
    this.amountReceivedError,
  }) : paymentDate = paymentDate ?? DateTime.now();

  final int? id;
  final Invoice? invoice;
  final PaymentMethod? paymentMethod;
  final String paymentReference;
  final double amount;
  final DateTime paymentDate;
  final int? creatorId;
  final DateTime? creationDate;
  final FormStatus status;
  final String? paymentMethodError;
  final String? referenceNumberError;
  final String? amountReceivedError;

  PaymentFormState Function({
    int? id,
    Invoice? invoice,
    PaymentMethod? paymentMethod,
    String? paymentReference,
    double? amount,
    DateTime? paymentDate,
    int? creatorId,
    DateTime? creationDate,
    FormStatus? status,
    String? paymentMethodError,
    String? referenceNumberError,
    String? amountReceivedError,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? invoice = undefined,
      Object? paymentMethod = undefined,
      Object? paymentReference = undefined,
      Object? amount = undefined,
      Object? paymentDate = undefined,
      Object? creatorId = undefined,
      Object? creationDate = undefined,
      Object? status = undefined,
      Object? paymentMethodError,
      Object? referenceNumberError,
      Object? amountReceivedError,
    }) {
      return PaymentFormState(
        id: id == undefined ? this.id : id as int?,
        invoice: invoice == undefined ? this.invoice : invoice as Invoice?,
        paymentMethod:
            paymentMethod == undefined ? this.paymentMethod : paymentMethod as PaymentMethod?,
        paymentReference:
            paymentReference == undefined ? this.paymentReference : paymentReference as String,
        amount: amount == undefined ? this.amount : amount as double,
        paymentDate: paymentDate == undefined ? this.paymentDate : paymentDate as DateTime?,
        creatorId: creatorId == undefined ? this.creatorId : creatorId as int?,
        creationDate: creationDate == undefined ? this.creationDate : creationDate as DateTime?,
        status: status == undefined ? this.status : status as FormStatus,
        paymentMethodError: paymentMethodError == undefined
            ? this.paymentMethodError
            : paymentMethodError as String?,
        referenceNumberError: referenceNumberError == undefined
            ? this.referenceNumberError
            : referenceNumberError as String?,
        amountReceivedError: amountReceivedError == undefined
            ? this.amountReceivedError
            : amountReceivedError as String?,
      );
    };
  }

  Payment toPayment() {
    return Payment(
      invoiceId: invoice!.id!,
      amount: amount,
      paymentDate: paymentDate,
      referenceNumber: paymentReference,
      paymentMethod: paymentMethod!.id!,
      creatorId: creatorId!,
      creationDate: creationDate!,
    );
  }
}
