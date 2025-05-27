part of 'navigation_bloc.dart';

sealed class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class NavigationIndexChanged with EquatableMixin implements NavigationEvent {
  const NavigationIndexChanged({
    required this.index,
  });

  final int index;

  @override
  List<Object> get props => [index];
}
