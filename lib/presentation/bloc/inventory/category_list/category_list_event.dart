part of 'category_list_bloc.dart';

sealed class CategoryListEvent extends Equatable {
  const CategoryListEvent();

  @override
  List<Object> get props => [];
}

class LoadCategoriesEvent extends CategoryListEvent {}

class ReloadCategoriesEvent extends CategoryListEvent {}

class AddCategoryEvent extends CategoryListEvent {
  const AddCategoryEvent(this.category);

  final Category category;

  @override
  List<Object> get props => [category];
}

class UpdateCategoryEvent extends CategoryListEvent {
  const UpdateCategoryEvent(this.category);

  final Category category;

  @override
  List<Object> get props => [category];
}

class DeleteCategoryEvent extends CategoryListEvent {
  const DeleteCategoryEvent(this.categoryId);
  final int categoryId;

  @override
  List<Object> get props => [categoryId];
}
