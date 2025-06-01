part of 'navigation_bloc.dart';

sealed class NavigationEvent {}

class NavigationIndexChanged with EquatableMixin implements NavigationEvent {
  const NavigationIndexChanged({
    required this.index,
    this.extra,
  });

  final int index;
  final Object? extra;

  @override
  List<Object?> get props => [index, extra];
}
