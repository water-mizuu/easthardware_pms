part of 'payment_method_form_cubit.dart';

class PaymentMethodFormState extends Equatable {
  const PaymentMethodFormState({
    this.name = '',
    this.status = FormStatus.initial,
  });

  final String name;
  final FormStatus status;

  PaymentMethodFormState Function({
    String? name,
    FormStatus? status,
  }) get copyWith {
    return ({
      Object? name = undefined,
      Object? status = undefined,
    }) {
      return PaymentMethodFormState(
        name: name.or(this.name),
        status: status.or(this.status),
      );
    };
  }

  PaymentMethod toPaymentMethod() {
    return PaymentMethod(name: name);
  }

  @override
  List<Object> get props => [name, status];
}
