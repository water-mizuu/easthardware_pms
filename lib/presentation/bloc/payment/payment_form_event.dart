part of 'payment_form_bloc.dart';

sealed class PaymentFormEvent extends Equatable {
  const PaymentFormEvent();

  @override
  List<Object> get props => [];
}

class InvoiceIdChanged extends PaymentFormEvent {
  const InvoiceIdChanged(this.invoiceId);

  final int invoiceId;

  @override
  List<Object> get props => [invoiceId];
}

class PaymentMethodChanged extends PaymentFormEvent {
  const PaymentMethodChanged(this.paymentMethodId, this.paymentMethodName);

  final int paymentMethodId;
  final String paymentMethodName;

  @override
  List<Object> get props => [paymentMethodId, paymentMethodName];
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
  const SavePaymentRequestEvent({required this.creatorId});

  final int creatorId;

  @override
  List<Object> get props => [];
}
