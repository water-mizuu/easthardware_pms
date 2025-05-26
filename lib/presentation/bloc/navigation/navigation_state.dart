part of 'navigation_bloc.dart';

class NavigationState {
  final int selectedIndex;
  final String currentRouteName;

  const NavigationState({
    required this.selectedIndex,
    required this.currentRouteName,
  });

  NavigationState Function({
    int selectedIndex,
    String currentRouteName,
  }) get copyWith {
    return ({
      Object? selectedIndex = undefined,
      Object? currentRouteName = undefined,
    }) {
      return NavigationState(
        selectedIndex: selectedIndex.or(this.selectedIndex),
        currentRouteName: currentRouteName.or(this.currentRouteName),
      );
    };
  }
}
