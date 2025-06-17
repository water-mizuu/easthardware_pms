part of 'payment_list_bloc.dart';

class PaymentListState extends Equatable {
  const PaymentListState({
    this.payments = const [],
    this.status = DataStatus.initial,
  });

  final List<Payment> payments;
  final DataStatus status;

  PaymentListState Function({
    List<Payment>? payments,
    DataStatus? status,
  }) get copyWith {
    return ({
      Object? payments = const [],
      Object? status = DataStatus.initial,
    }) {
      return PaymentListState(
        payments: payments == const [] ? this.payments : payments as List<Payment>,
        status: status == DataStatus.initial ? this.status : status as DataStatus,
      );
    };
  }

  @override
  List<Object> get props => [];
}
