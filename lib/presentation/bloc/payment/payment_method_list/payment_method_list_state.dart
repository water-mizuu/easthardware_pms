part of 'payment_method_list_bloc.dart';

class PaymentMethodListState {
  const PaymentMethodListState({
    this.paymentMethods = const [],
    this.status = DataStatus.initial,
  });

  final List<PaymentMethod> paymentMethods;
  final DataStatus status;

  PaymentMethodListState copyWith({
    Object? paymentMethods = undefined,
    Object? status = undefined,
  }) {
    return PaymentMethodListState(
      paymentMethods:
          paymentMethods == undefined ? this.paymentMethods : paymentMethods as List<PaymentMethod>,
      status: status == undefined ? this.status : status as DataStatus,
    );
  }
}
