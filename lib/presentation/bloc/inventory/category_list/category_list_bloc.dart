import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/repository/category_repository.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

part 'category_list_event.dart';
part 'category_list_state.dart';

class CategoryListBloc extends Bloc<CategoryListEvent, CategoryListState> {
  CategoryListBloc(this._repository, CategoryListState initialState) : super(initialState) {
    on<LoadCategoriesEvent>(_onLoad);
    on<ReloadCategoriesEvent>(_onReload);
    on<AddCategoryEvent>(_onAdd);
    on<UpdateCategoryEvent>(_onUpdate);
    on<DeleteCategoryEvent>(_onDelete);
  }

  final CategoryRepository _repository;

  Future<void> _onLoad(LoadCategoriesEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      emit(state.copyWith(
        categories: await _repository.getAllCategories(),
        status: DataStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onReload(ReloadCategoriesEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      emit(state.copyWith(
        categories: await _repository.getAllCategories(),
        status: DataStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAdd(AddCategoryEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final category = await _repository.insertCategory(event.category);
      final categories = state.categories..add(category);
      emit(state.copyWith(categories: categories, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onUpdate(UpdateCategoryEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      _repository.updateCategory(event.category);
      final categories = state.categories.toList();
      final index = categories.indexWhere((category) => category.id == event.category.id);
      categories[index] = event.category;
      emit(state.copyWith(categories: categories, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onDelete(DeleteCategoryEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      _repository.deleteCategory(event.categoryId);
      final categories = state.categories.toList();
      categories.removeWhere((category) => category.id == event.categoryId);
      emit(state.copyWith(categories: categories, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }
}
