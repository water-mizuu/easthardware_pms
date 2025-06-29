import 'package:easthardware_pms/presentation/views/dashboard/cards/expense_breakdown_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'expense_breakdown_state.dart';

class ExpenseBreakdownCubit extends Cubit<ExpenseBreakdownState> {
  ExpenseBreakdownCubit() : super(ExpenseBreakdownState.initial());

  void setChoice(ExpenseBreakdownChoice choice) {
    emit(state.copyWith(choice: choice));
  }
}
