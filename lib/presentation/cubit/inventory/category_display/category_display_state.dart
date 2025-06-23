part of 'category_display_cubit.dart';

class CategoryDisplayState with EquatableMixin {
  const CategoryDisplayState({
    this.allCategories,
    this.filteredCategories,
    this.searchQuery = '',
    this.sortBy = CategoryDisplaySortBy.nameAscending,
    this.sortAscending = true,
  });

  CategoryDisplayState.empty()
      : allCategories = null,
        filteredCategories = null,
        searchQuery = '',
        sortBy = CategoryDisplaySortBy.nameAscending,
        sortAscending = true;

  final List<Category>? allCategories;
  final List<Category>? filteredCategories;
  final String searchQuery;
  final CategoryDisplaySortBy sortBy;
  final bool sortAscending;

  CategoryDisplayState Function({
    List<Category>? allCategories,
    List<Category>? filteredCategories,
    String searchQuery,
    CategoryDisplaySortBy sortBy,
    bool sortAscending,
  }) get copyWith {
    return ({
      Object? allCategories = undefined,
      Object? filteredCategories = undefined,
      Object? searchQuery = undefined,
      Object? sortBy = undefined,
      Object? sortAscending = undefined,
    }) {
      return CategoryDisplayState(
        allCategories: allCategories.or(this.allCategories),
        filteredCategories: filteredCategories.or(this.filteredCategories),
        searchQuery: searchQuery.or(this.searchQuery),
        sortBy: sortBy.or(this.sortBy),
        sortAscending: sortAscending.or(this.sortAscending),
      );
    };
  }

  @override
  List<Object?> get props => [
        allCategories,
        filteredCategories,
        searchQuery,
        sortBy,
        sortAscending,
      ];
}
