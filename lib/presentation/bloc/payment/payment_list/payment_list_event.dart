part of 'payment_list_bloc.dart';

sealed class PaymentListEvent extends Equatable {
  const PaymentListEvent();

  @override
  List<Object> get props => [];
}

class FetchAllPaymentsEvent extends PaymentListEvent {
  const FetchAllPaymentsEvent();

  @override
  List<Object> get props => [];
}

class AddPaymentEvent extends PaymentListEvent {
  const AddPaymentEvent(this.payment);

  final Payment payment;

  @override
  List<Object> get props => [payment];
}

class UpdatePaymentEvent extends PaymentListEvent {
  const UpdatePaymentEvent(this.payment);

  final Payment payment;

  @override
  List<Object> get props => [payment];
}
