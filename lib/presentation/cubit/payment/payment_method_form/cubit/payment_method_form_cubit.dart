import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart' show FormStatus;
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:fluent_ui/fluent_ui.dart';

part 'payment_method_form_state.dart';

class PaymentMethodFormCubit extends Cubit<PaymentMethodFormState> {
  PaymentMethodFormCubit()
      : formkey = GlobalKey<FormState>(),
        super(const PaymentMethodFormState());
  final GlobalKey<FormState> formkey;

  void onFormNameChanged(String name) {
    emit(state.copyWith(name: name));
  }
}
