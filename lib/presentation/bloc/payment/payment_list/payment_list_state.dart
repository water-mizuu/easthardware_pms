part of 'payment_list_bloc.dart';

class PaymentListState {
  const PaymentListState({
    this.payments = const [],
    this.status = DataStatus.initial,
    this.latest,
  });

  final List<Payment> payments;
  final DataStatus status;
  final Payment? latest;

  PaymentListState Function({
    List<Payment>? payments,
    DataStatus? status,
    Payment? latest,
  }) get copyWith {
    return ({
      Object? payments = undefined,
      Object? status = undefined,
      Object? latest = undefined,
    }) {
      return PaymentListState(
        payments: payments == undefined ? this.payments : payments as List<Payment>,
        status: status == undefined ? this.status : status as DataStatus,
        latest: latest == undefined ? this.latest : latest as Payment?,
      );
    };
  }
}
