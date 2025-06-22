import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:flutter/widgets.dart';

part 'expense_type_form_state.dart';

class ExpenseTypeFormCubit extends Cubit<ExpenseTypeFormState> {
  ExpenseTypeFormCubit()
      : formKey = GlobalKey<FormState>(),
        super(const ExpenseTypeFormState());

  final GlobalKey<FormState> formKey;

  void onNameChanged(String name) {
    emit(state.copyWith(name: name));
  }

  Future<void> onButtonPressed(
      {List<String>? existingNames, bool isAdding = true, String? currentName}) async {
    emit(state.copyWith(status: FormStatus.validating));
    await Future.delayed(Duration.zero);

    // Validate name
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(status: FormStatus.error, errorMessage: 'Name cannot be empty'));
      return;
    }

    // Check if name already exists (only if we have a list of existing names)
    if (existingNames != null) {
      final trimmedName = state.name.trim();
      if (existingNames.contains(trimmedName)) {
        // If adding, or if editing and new name is different from current name
        if (isAdding || (trimmedName != currentName?.trim())) {
          emit(state.copyWith(
              status: FormStatus.error, errorMessage: 'Expense type already exists'));
          return;
        }
      }
    }

    if (formKey.currentState?.mounted != true) return;
    if (formKey.currentState case final FormState formState when formState.validate()) {
      emit(state.copyWith(status: FormStatus.submitting));
    }
  }

  void onSubmit() {
    emit(state.copyWith(status: FormStatus.submitted));
  }

  void onFormReset() {
    emit(const ExpenseTypeFormState());
  }
}
