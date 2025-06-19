import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/payment.dart';
import 'package:easthardware_pms/domain/repository/payment_repository.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

part 'payment_list_event.dart';
part 'payment_list_state.dart';

class PaymentListBloc extends Bloc<PaymentListEvent, PaymentListState> {
  PaymentListBloc(
    this._repository,
    PaymentListState initialState,
  ) : super(initialState) {
    on<FetchAllPaymentsEvent>(_onFetchPaymentList);
    on<AddPaymentEvent>(_onAddPayment);
    on<UpdatePaymentEvent>(_onUpdatePayment);
  }

  final PaymentRepository _repository;

  Future<void> _onFetchPaymentList(
      FetchAllPaymentsEvent event, Emitter<PaymentListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final payments = await _repository.getAllPayments();
      emit(state.copyWith(payments: payments, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAddPayment(AddPaymentEvent event, Emitter<PaymentListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final payment = await _repository.insertPayment(event.payment);
      emit(
        state.copyWith(
          payments: [...state.payments, payment],
          latest: payment,
          status: DataStatus.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onUpdatePayment(UpdatePaymentEvent event, Emitter<PaymentListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final payment = await _repository.updatePayment(event.payment);
      final updatedPayments = state.payments.map((p) {
        return p.id == payment.id ? payment : p;
      }).toList();
      emit(state.copyWith(
        payments: updatedPayments,
        latest: payment,
        status: DataStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }
}
