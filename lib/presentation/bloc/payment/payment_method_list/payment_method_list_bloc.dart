import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart' show DataStatus;
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/domain/repository/payment_method_repository.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

part 'payment_method_list_event.dart';
part 'payment_method_list_state.dart';

class PaymentMethodListBloc extends Bloc<PaymentMethodListEvent, PaymentMethodListState> {
  PaymentMethodListBloc(this._repository, PaymentMethodListState state) : super(state) {
    on<FetchAllPaymentMethodsEvent>(_onFetchPaymentMethods);
    on<AddPaymentMethodEvent>(_onAddPaymentInvoice);
    on<UpdatePaymentMethodEvent>(_onUpdatePaymentInvoice);
  }

  final PaymentMethodRepository _repository;

  Future<void> _onFetchPaymentMethods(FetchAllPaymentMethodsEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final paymentMethods = await _repository.getAllPaymentMethods();
      emit(state.copyWith(paymentMethods: paymentMethods, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAddPaymentInvoice(AddPaymentMethodEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final paymentMethod = await _repository.insertPaymentMethod(event.paymentMethod);
      final paymentMethods = List.from(state.paymentMethods)..remove(paymentMethod);
      emit(state.copyWith(paymentMethods: paymentMethods, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onUpdatePaymentInvoice(UpdatePaymentMethodEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final paymentMethod = await _repository.updatePaymentMethod(event.paymentMethod);
      final paymentMethods = List<PaymentMethod>.from(state.paymentMethods)
        ..removeWhere((e) => e.id == event.paymentMethod.id)
        ..add(paymentMethod);
      emit(state.copyWith(paymentMethods: paymentMethods, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }
}
