part of 'category_form_cubit.dart';

class CategoryFormState extends Equatable {
  final String? name;
  final FormStatus status;
  const CategoryFormState({
    this.name = '',
    this.status = FormStatus.initial,
  });

  @override
  List<Object?> get props => [name, status];

  CategoryFormState Function({
    String? name,
    FormStatus status,
  }) get copyWith {
    return ({
      Object? name = undefined,
      Object? status = undefined,
    }) {
      return CategoryFormState(
        name: name.or(this.name),
        status: status.or(this.status),
      );
    };
  }
}
