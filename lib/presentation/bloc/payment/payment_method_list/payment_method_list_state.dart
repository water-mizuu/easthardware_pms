part of 'payment_method_list_bloc.dart';

class PaymentMethodListState with EquatableMixin {
  const PaymentMethodListState({
    this.paymentMethods = const [],
    this.status = DataStatus.initial,
  });

  final List<PaymentMethod> paymentMethods;
  final DataStatus status;

  PaymentMethodListState Function({
    List<PaymentMethod> paymentMethods,
    DataStatus status,
  }) get copyWith {
    return ({
      Object paymentMethods = undefined,
      Object status = undefined,
    }) {
      return PaymentMethodListState(
        paymentMethods: paymentMethods.or(this.paymentMethods),
        status: status.or(this.status),
      );
    };
  }

  @override
  List<Object?> get props => [paymentMethods, status];
}
