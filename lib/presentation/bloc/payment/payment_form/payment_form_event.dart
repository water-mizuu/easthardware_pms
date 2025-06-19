part of 'payment_form_bloc.dart';

sealed class PaymentFormEvent extends Equatable {
  const PaymentFormEvent();

  @override
  List<Object> get props => [];
}

class InvoiceChanged extends PaymentFormEvent {
  const InvoiceChanged(this.invoice);

  final Invoice invoice;

  @override
  List<Object> get props => [invoice];
}

class PaymentMethodChanged extends PaymentFormEvent {
  const PaymentMethodChanged(this.paymentMethod);

  final PaymentMethod paymentMethod;

  @override
  List<Object> get props => [paymentMethod];
}

class PaymentReferenceChanged extends PaymentFormEvent {
  const PaymentReferenceChanged(this.paymentReference);

  final String paymentReference;

  @override
  List<Object> get props => [paymentReference];
}

class AmountChanged extends PaymentFormEvent {
  const AmountChanged(this.amount);

  final double amount;

  @override
  List<Object> get props => [amount];
}

class PaymentDateChanged extends PaymentFormEvent {
  const PaymentDateChanged(this.paymentDate);

  final DateTime paymentDate;

  @override
  List<Object> get props => [paymentDate];
}

class SavePaymentRequestEvent extends PaymentFormEvent {
  const SavePaymentRequestEvent();

  @override
  List<Object> get props => [];
}

class FormSubmittedEvent extends PaymentFormEvent {}
