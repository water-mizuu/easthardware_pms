import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'payment_method_form_state.dart';

class PaymentMethodFormCubit extends Cubit<PaymentMethodFormState> {
  PaymentMethodFormCubit()
      : super(
          const PaymentMethodFormState(
            name: '',
            status: FormStatus.initial,
            errorMessage: null,
          ),
        );

  final formKey = GlobalKey<FormState>();

  void onNameChanged(String name) {
    emit(state.copyWith(name: name, status: FormStatus.initial));
  }

  void onFormReset() {
    emit(const PaymentMethodFormState(
      name: '',
      status: FormStatus.initial,
      errorMessage: null,
    ));
  }

  void onSubmit() {
    emit(state.copyWith(status: FormStatus.submitted));
  }

  void onButtonPressed({
    required List<String> existingNames,
    required bool isAdding,
    String? currentName,
  }) {
    final name = state.name.trim();

    // Validate name is not empty
    if (name.isEmpty) {
      emit(state.copyWith(
        status: FormStatus.error,
        errorMessage: 'Payment method name cannot be empty',
      ));
      return;
    }

    // When adding new payment method or updating with a different name
    // check if the name already exists
    if (isAdding || name != currentName) {
      if (existingNames.contains(name)) {
        emit(state.copyWith(
          status: FormStatus.error,
          errorMessage: 'Payment method name already exists',
        ));
        return;
      }
    }

    emit(state.copyWith(status: FormStatus.submitting));
  }
}
