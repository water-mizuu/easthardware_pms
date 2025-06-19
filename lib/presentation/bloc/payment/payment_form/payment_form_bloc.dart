import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/payment.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

part 'payment_form_event.dart';
part 'payment_form_state.dart';

class PaymentFormBloc extends Bloc<PaymentFormEvent, PaymentFormState> {
  PaymentFormBloc() : super(PaymentFormState()) {
    on<InvoiceChanged>(_onInvoiceChanged);
    on<PaymentMethodChanged>(_onPaymentMethodChanged);
    on<PaymentReferenceChanged>(_onPaymentReferenceChanged);
    on<AmountChanged>(_onAmountChanged);
    on<PaymentDateChanged>(_onPaymentDateChanged);
    on<SavePaymentRequestEvent>(_onSavePaymentRequestEvent);
  }

  void _onInvoiceChanged(InvoiceChanged event, Emitter<PaymentFormState> emit) {
    emit(state.copyWith(invoice: event.invoice));
  }

  void _onPaymentMethodChanged(PaymentMethodChanged event, Emitter<PaymentFormState> emit) {
    emit(state.copyWith(paymentMethod: event.paymentMethod, status: FormStatus.initial));
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

  void _onSavePaymentRequestEvent(SavePaymentRequestEvent event, Emitter<PaymentFormState> emit) {
    emit(state.copyWith(status: FormStatus.validating));
    Future.delayed(Duration.zero);
    try {
      final paymentMethodError = state.paymentMethod == null //
          ? 'A payment method must be selected'
          : null;
      final refrenceMethodError = state.paymentReference.isEmpty //
          ? 'A reference number must be provided'
          : null;
      final amountReceivedError = state.amount == 0 //
          ? 'Amount received cannot be empty'
          : null;

      final errorPersists = paymentMethodError != null ||
          refrenceMethodError != null || //
          amountReceivedError != null;
      if (errorPersists) {
        printBoxed(
            '$paymentMethodError, $refrenceMethodError, $amountReceivedError', 'PaymentFormBloc');
        return emit(state.copyWith(
          paymentMethodError: paymentMethodError,
          referenceNumberError: refrenceMethodError,
          amountReceivedError: amountReceivedError,
          status: FormStatus.error,
        ));
      }
      return emit(state.copyWith(status: FormStatus.submitting));
    } catch (e, stackTrace) {
      printBoxed('$e\n$stackTrace', 'PaymentFormBloc');
    }
  }
}
