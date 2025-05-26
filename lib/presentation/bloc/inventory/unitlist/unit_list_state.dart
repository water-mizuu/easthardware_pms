part of 'unit_list_bloc.dart';

class UnitListState {
  const UnitListState({
    required this.status,
    required this.units,
    this.filteredUnits,
  });

  final DataStatus status;
  final List<Unit> units;
  final List<Unit>? filteredUnits;

  UnitListState Function({
    DataStatus status,
    List<Unit> units,
    List<Unit>? filteredUnits,
  }) get copyWith {
    return ({
      Object? status = undefined,
      Object? units = undefined,
      Object? filteredUnits = undefined,
    }) {
      return UnitListState(
        status: status.or(this.status),
        units: units.or(this.units),
        filteredUnits: filteredUnits.or(this.filteredUnits),
      );
    };
  }
}

final class UnitListInitial extends UnitListState {
  UnitListInitial()
      : super(
          status: DataStatus.initial,
          units: [],
        );
}
