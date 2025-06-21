import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/repository/expense_type_repository.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

part 'expense_type_list_event.dart';
part 'expense_type_list_state.dart';

class ExpenseTypeListBloc extends Bloc<ExpenseTypeListEvent, ExpenseTypeListState> {
  ExpenseTypeListBloc(this._repository, ExpenseTypeListState initialState) : super(initialState) {
    on<FetchAllExpenseTypesEvent>(_onFetchAllExpenseTypes);
    on<AddExpenseTypeEvent>(_onAddExpenseType);
    on<UpdateExpenseTypeEvent>(_onUpdateExpenseType);
  }
  final ExpenseTypeRepository _repository;

  Future<void> _onFetchAllExpenseTypes(
    FetchAllExpenseTypesEvent event,
    Emitter<ExpenseTypeListState> emit,
  ) async {
    printBoxed("Fetching all expense types");
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final expenseTypes = await _repository.getAllExpenseTypes();
      emit(state.copyWith(expenseTypes: expenseTypes, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAddExpenseType(
    AddExpenseTypeEvent event,
    Emitter<ExpenseTypeListState> emit,
  ) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final expenseType = await _repository.insertExpenseType(event.expenseType);
      final expenseTypes = [...state.expenseTypes, expenseType];
      emit(state.copyWith(expenseTypes: expenseTypes, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onUpdateExpenseType(
    UpdateExpenseTypeEvent event,
    Emitter<ExpenseTypeListState> emit,
  ) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final expenseType = await _repository.updateExpenseType(event.expenseType);
      final expenseTypes = List<ExpenseType>.from(state.expenseTypes)
        ..removeWhere((e) => e.id == expenseType.id)
        ..add(expenseType);
      emit(state.copyWith(expenseTypes: expenseTypes, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }
}
