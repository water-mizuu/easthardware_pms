part of 'category_list_bloc.dart';

class CategoryListState {
  final List<Category> categories;
  final DataStatus status;

  CategoryListState(this.categories, this.status);

  CategoryListState Function({
    List<Category> categories,
    DataStatus status,
  }) get copyWith {
    return ({
      Object? categories = undefined,
      Object? status = undefined,
    }) {
      return CategoryListState(
        categories.or(this.categories),
        status.or(this.status),
      );
    };
  }
}

final class CategoryListInitial extends CategoryListState {
  CategoryListInitial() : super([], DataStatus.initial);
}
