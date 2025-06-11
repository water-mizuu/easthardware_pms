part of 'unit_list_bloc.dart';

class UnitListState {
  const UnitListState({
    required this.status,
    required this.units,
    this.filteredUnits,
    this.errorMessage,
  });

  const UnitListState.initial()
      : status = DataStatus.initial,
        units = const [],
        filteredUnits = null,
        errorMessage = null;

  final DataStatus status;
  final List<Unit> units;
  final List<Unit>? filteredUnits;
  final String? errorMessage;

  UnitListState Function({
    DataStatus status,
    List<Unit> units,
    List<Unit>? filteredUnits,
    String? errorMessage,
  }) get copyWith {
    return ({
      Object? status = undefined,
      Object? units = undefined,
      Object? filteredUnits = undefined,
      Object? errorMessage = undefined,
    }) {
      return UnitListState(
        status: status.or(this.status),
        units: units.or(this.units),
        filteredUnits: filteredUnits.or(this.filteredUnits),
        errorMessage: errorMessage.or(this.errorMessage),
      );
    };
  }
}
