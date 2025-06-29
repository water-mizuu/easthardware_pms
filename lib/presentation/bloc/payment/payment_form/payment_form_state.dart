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
    this.lastAutomatedUpdate,
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
  final DateTime? lastAutomatedUpdate;

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
    DateTime? lastAutomatedUpdate,
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
      Object? lastAutomatedUpdate = undefined,
    }) {
      return PaymentFormState(
        id: id.or(this.id),
        invoice: invoice.or(this.invoice),
        paymentMethod: paymentMethod.or(this.paymentMethod),
        paymentReference: paymentReference.or(this.paymentReference),
        amount: amount.or(this.amount),
        paymentDate: paymentDate.or(this.paymentDate),
        creatorId: creatorId.or(this.creatorId),
        creationDate: creationDate.or(this.creationDate),
        status: status.or(this.status),
        paymentMethodError: paymentMethodError.or(this.paymentMethodError),
        referenceNumberError: referenceNumberError.or(this.referenceNumberError),
        amountReceivedError: amountReceivedError.or(this.amountReceivedError),
        lastAutomatedUpdate: lastAutomatedUpdate.or(this.lastAutomatedUpdate),
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
