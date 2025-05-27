import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'reset_form_event.dart';
part 'reset_form_state.dart';

class ResetFormBloc extends Bloc<ResetFormEvent, ResetFormState> {
  ResetFormBloc() : super(ResetformInitial()) {
    on<ResetFormEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
