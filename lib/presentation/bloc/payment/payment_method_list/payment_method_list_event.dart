part of 'payment_method_list_bloc.dart';

sealed class PaymentMethodListEvent extends Equatable {
  const PaymentMethodListEvent();

  @override
  List<Object> get props => [];
}

class FetchAllPaymentMethodsEvent extends PaymentMethodListEvent {
  const FetchAllPaymentMethodsEvent();

  @override
  List<Object> get props => [];
}

class AddPaymentMethodEvent extends PaymentMethodListEvent {
  const AddPaymentMethodEvent(this.paymentMethod);

  final PaymentMethod paymentMethod;

  @override
  List<Object> get props => [paymentMethod];
}

class UpdatePaymentMethodEvent extends PaymentMethodListEvent {
  const UpdatePaymentMethodEvent(this.paymentMethod);

  final PaymentMethod paymentMethod;

  @override
  List<Object> get props => [paymentMethod];
}
