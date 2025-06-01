import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Cubit<NavigationState> {
  NavigationBloc() : super(const NavigationState(selectedIndex: 0));

  void goIndex(int index) {
    emit(state.copyWith(selectedIndex: index));
  }

  void goOutsideOfNavigation() {
    emit(state.copyWith(selectedIndex: null));
  }
}
