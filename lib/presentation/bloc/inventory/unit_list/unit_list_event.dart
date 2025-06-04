part of 'unit_list_bloc.dart';

sealed class UnitListEvent extends Equatable {
  const UnitListEvent();

  @override
  List<Object> get props => [];
}

class LoadUnitsEvent extends UnitListEvent {
  const LoadUnitsEvent();
}

class ReloadUnitsEvent extends UnitListEvent {
  const ReloadUnitsEvent();
}

class FilterUnitsEvent extends UnitListEvent {
  const FilterUnitsEvent(this.productId);
  final int productId;
}

class AddUnitEvent extends UnitListEvent {
  const AddUnitEvent(this.unit);
  final Unit unit;
}

class UpdateUnitEvent extends UnitListEvent {
  const UpdateUnitEvent(this.unit);
  final Unit unit;
}

class DeleteUnitEvent extends UnitListEvent {
  const DeleteUnitEvent(this.unitId);
  final int unitId;
}
