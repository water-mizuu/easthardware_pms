import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/domain/repository/unit_repository.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:easthardware_pms/domain/constants/debug_constants.dart';
import 'package:equatable/equatable.dart';

part 'unit_list_event.dart';
part 'unit_list_state.dart';

class UnitListBloc extends Bloc<UnitListEvent, UnitListState> {
  UnitListBloc(this._repository, UnitListState initialState) : super(initialState) {
    on<LoadUnitsEvent>(_onLoad);
    on<ReloadUnitsEvent>(_onReload);
    on<AddUnitEvent>(_onAdd);
    on<UpdateUnitEvent>(_onUpdate);
    on<DeleteUnitEvent>(_onDelete);
    on<FilterUnitsEvent>(_onFilter);
  }

  final UnitRepository _repository;

  Future<void> _onLoad(LoadUnitsEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      emit(state.copyWith(
        units: await _repository.getAllUnits(),
        status: DataStatus.success,
      ));
      if (isDebugMode) {
        printBoxed('Units loaded: ${state.units.length}');
      }
    } catch (e) {
      if (isDebugMode) {
        printBoxed('Error loading units: $e');
      }
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onFilter(FilterUnitsEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    Future.delayed(Duration.zero, () {
      final filteredUnits = state.units.where((unit) {
        return unit.productId! == event.productId;
      }).toList();
      emit(state.copyWith(filteredUnits: filteredUnits, status: DataStatus.success));
    });
  }

  Future<void> _onReload(ReloadUnitsEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      emit(state.copyWith(
        units: await _repository.getAllUnits(),
        filteredUnits: null,
        status: DataStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onAdd(AddUnitEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _repository.insertUnit(event.unit);
      emit(state.copyWith(
        units: await _repository.getAllUnits(),
        status: DataStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateUnitEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _repository.updateUnit(event.unit);
      emit(state.copyWith(
        units: await _repository.getAllUnits(),
        status: DataStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onDelete(DeleteUnitEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _repository.deleteUnit(event.unitId);
      emit(state.copyWith(
        units: await _repository.getAllUnits(),
        status: DataStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error, errorMessage: e.toString()));
    }
  }
}
