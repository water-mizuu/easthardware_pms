import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/payment.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

part 'payment_form_event.dart';
part 'payment_form_state.dart';

class PaymentFormBloc extends Bloc<PaymentFormEvent, PaymentFormState> {
  PaymentFormBloc() : super(PaymentFormState()) {
    on<InvoiceIdChanged>(_onInvoiceIdChanged);
    on<PaymentMethodChanged>(_onPaymentMethodChanged);
    on<PaymentReferenceChanged>(_onPaymentReferenceChanged);
    on<AmountChanged>(_onAmountChanged);
    on<PaymentDateChanged>(_onPaymentDateChanged);
    on<SavePaymentRequestEvent>(_onSavePaymentRequestEvent);
  }

  void _onInvoiceIdChanged(InvoiceIdChanged event, Emitter<PaymentFormState> emit) {
    emit(state.copyWith(invoiceId: event.invoiceId));
  }

  void _onPaymentMethodChanged(PaymentMethodChanged event, Emitter<PaymentFormState> emit) {
    emit(state.copyWith(
      paymentMethodId: event.paymentMethodId,
      paymentMethodName: event.paymentMethodName,
    ));
  }

  void _onPaymentReferenceChanged(PaymentReferenceChanged event, Emitter<PaymentFormState> emit) {
    emit(state.copyWith(paymentReference: event.paymentReference));
  }

  void _onAmountChanged(AmountChanged event, Emitter<PaymentFormState> emit) {
    emit(state.copyWith(amount: event.amount));
  }

  void _onPaymentDateChanged(PaymentDateChanged event, Emitter<PaymentFormState> emit) {
    emit(state.copyWith(paymentDate: event.paymentDate));
  }

  void _onSavePaymentRequestEvent(SavePaymentRequestEvent event, Emitter<PaymentFormState> emit) {}
}
