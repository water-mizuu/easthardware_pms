import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState(selectedIndex: 0, currentRouteName: '/')) {
    on<NavigationIndexChanged>((event, emit) {
      emit(state.copyWith(selectedIndex: event.index));
    });
  }
}
