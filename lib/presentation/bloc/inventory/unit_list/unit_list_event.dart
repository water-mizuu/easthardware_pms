part of 'unit_list_bloc.dart';

sealed class UnitListEvent extends Equatable {
  const UnitListEvent();

  @override
  List<Object> get props => [];
}

class LoadUnitsEvent extends UnitListEvent {}

class ReloadUnitsEvent extends UnitListEvent {}

class FilterUnitsEvent extends UnitListEvent {
  final int productId;

  const FilterUnitsEvent(this.productId);
}

class AddUnitEvent extends UnitListEvent {
  final Unit unit;

  const AddUnitEvent(this.unit);
}

class UpdateUnitEvent extends UnitListEvent {
  final Unit unit;

  const UpdateUnitEvent(this.unit);
}

class DeleteUnitEvent extends UnitListEvent {
  final int unitId;

  const DeleteUnitEvent(this.unitId);
}
