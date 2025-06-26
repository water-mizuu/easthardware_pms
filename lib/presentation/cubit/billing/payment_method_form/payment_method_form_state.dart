part of 'payment_method_form_cubit.dart';

class PaymentMethodFormState extends Equatable {
  final String name;
  final FormStatus status;
  final String? errorMessage;

  const PaymentMethodFormState({
    required this.name,
    required this.status,
    this.errorMessage,
  });

  PaymentMethodFormState copyWith({
    String? name,
    FormStatus? status,
    String? errorMessage,
  }) {
    return PaymentMethodFormState(
      name: name ?? this.name,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [name, status, errorMessage];
}
