part of 'payment_form_bloc.dart';

sealed class PaymentFormEvent extends Equatable {
  const PaymentFormEvent();

  @override
  List<Object?> get props => [];
}

class InvoiceCleared extends PaymentFormEvent {
  const InvoiceCleared();

  @override
  List<Object?> get props => [];
}

class InvoiceChanged extends PaymentFormEvent {
  const InvoiceChanged(this.invoice, {required this.isUserInput});

  final Invoice invoice;
  final bool isUserInput;

  @override
  List<Object?> get props => [invoice, isUserInput];
}

class PaymentMethodChanged extends PaymentFormEvent {
  const PaymentMethodChanged(this.paymentMethod);

  final PaymentMethod paymentMethod;

  @override
  List<Object?> get props => [paymentMethod];
}

class PaymentReferenceChanged extends PaymentFormEvent {
  const PaymentReferenceChanged(this.paymentReference);

  final String paymentReference;

  @override
  List<Object?> get props => [paymentReference];
}

class PaymentMethodErrorChanged extends PaymentFormEvent {
  const PaymentMethodErrorChanged(this.paymentMethodError);

  final String? paymentMethodError;

  @override
  List<Object?> get props => [paymentMethodError];
}

class ReferenceNumberErrorChanged extends PaymentFormEvent {
  const ReferenceNumberErrorChanged(this.referenceNumberError);

  final String? referenceNumberError;

  @override
  List<Object?> get props => [referenceNumberError];
}

class InvoiceNumberErrorChanged extends PaymentFormEvent {
  const InvoiceNumberErrorChanged(this.invoiceNumberError);

  final String? invoiceNumberError;

  @override
  List<Object?> get props => [invoiceNumberError];
}

class AmountReceivedErrorChanged extends PaymentFormEvent {
  const AmountReceivedErrorChanged(this.amountReceivedError);

  final String? amountReceivedError;

  @override
  List<Object?> get props => [amountReceivedError];
}

class AmountChanged extends PaymentFormEvent {
  const AmountChanged(this.amount);

  final double amount;

  @override
  List<Object?> get props => [amount];
}

class PaymentDateChanged extends PaymentFormEvent {
  const PaymentDateChanged(this.paymentDate);

  final DateTime paymentDate;

  @override
  List<Object?> get props => [paymentDate];
}

class PrintPaymentRequestEvent extends PaymentFormEvent {
  const PrintPaymentRequestEvent();

  @override
  List<Object?> get props => [];
}

class SavePaymentRequestEvent extends PaymentFormEvent {
  const SavePaymentRequestEvent();

  @override
  List<Object?> get props => [];
}

class FormSubmittedEvent extends PaymentFormEvent {}
