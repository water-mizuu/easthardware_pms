import 'dart:async';

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
    on<InvoiceCleared>(_onInvoiceCleared);
    on<PaymentMethodChanged>(_onPaymentMethodChanged);
    on<PaymentReferenceChanged>(_onPaymentReferenceChanged);
    on<AmountChanged>(_onAmountChanged);
    on<PaymentDateChanged>(_onPaymentDateChanged);
    on<PrintPaymentRequestEvent>(_onPrintPaymentRequestEvent);
    on<SavePaymentRequestEvent>(_onSavePaymentRequestEvent);
    on<FormSubmittedEvent>(_onFormSubmitted);
  }

  void _onInvoiceChanged(InvoiceChanged event, Emitter<PaymentFormState> emit) {
    emit(state.copyWith(invoice: event.invoice));
  }

  void _onInvoiceCleared(InvoiceCleared event, Emitter<PaymentFormState> emit) {
    emit(state.copyWith(invoice: null));
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

  Future<void> _onSavePaymentRequestEvent(
    SavePaymentRequestEvent event,
    Emitter<PaymentFormState> emit,
  ) async {
    emit(state.copyWith(status: FormStatus.validating));

    try {
      final isValid = await _validateForms(emit);
      if (!isValid) return;

      emit(state.copyWith(status: FormStatus.submitting));
    } catch (e, stackTrace) {
      printBoxed('$e\n$stackTrace', 'PaymentFormBloc');
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onPrintPaymentRequestEvent(
    PrintPaymentRequestEvent event,
    Emitter<PaymentFormState> emit,
  ) async {
    emit(state.copyWith(status: FormStatus.validating));

    try {
      final isValid = await _validateForms(emit);
      if (!isValid) return;

      emit(state.copyWith(status: FormStatus.printing));
    } catch (e, stackTrace) {
      printBoxed('$e\n$stackTrace', 'PaymentFormBloc');

      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onFormSubmitted(FormSubmittedEvent event, Emitter<PaymentFormState> emit) async {
    emit(state.copyWith(status: FormStatus.initial));
  }

  Future<bool> _validateForms(Emitter<PaymentFormState> emit) async {
    final alreadyClosed = state.invoice!.paymentDate != null;
    final paymentMethodError = state.paymentMethod == null //
        ? 'A payment method must be selected'
        : null;
    final referenceMethodError = state.paymentReference.isEmpty //
        ? 'A reference number must be provided'
        : null;
    final amountReceivedError = state.amount == 0 //
        ? 'Amount received cannot be empty'
        : null;

    final errorPersists = alreadyClosed ||
        paymentMethodError != null ||
        referenceMethodError != null ||
        amountReceivedError != null;

    if (errorPersists) {
      emit(
        state.copyWith(
          paymentMethodError: paymentMethodError,
          referenceNumberError: referenceMethodError,
          amountReceivedError: amountReceivedError,
          status: FormStatus.error,
        ),
      );

      return false;
    } else {
      return true;
    }
  }
}
