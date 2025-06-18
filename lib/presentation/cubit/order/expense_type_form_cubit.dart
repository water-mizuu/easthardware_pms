import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/utils/undefined.dart';

part 'expense_type_form_state.dart';

class ExpenseTypeFormCubit extends Cubit<ExpenseTypeFormState> {
  ExpenseTypeFormCubit() : super(const ExpenseTypeFormState());

  void onNameChanged(String name) {
    emit(state.copyWith(name: name));
  }
}
