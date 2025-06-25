part of 'category_display_cubit.dart';

class DisplayCategory {
  factory DisplayCategory.fromCategory(Category category, {int? productCount}) {
    return DisplayCategory(
      category: category,
      displayName: category.name,
      productCount: productCount,
    );
  }
  const DisplayCategory({
    required this.category,
    required this.displayName,
    this.productCount,
  });

  final Category category;
  final String displayName;
  final int? productCount;

  @override
  String toString() => displayName;
}

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

  final List<DisplayCategory>? allCategories;
  final List<DisplayCategory>? filteredCategories;
  final String searchQuery;
  final CategoryDisplaySortBy sortBy;
  final bool sortAscending;

  CategoryDisplayState Function({
    List<DisplayCategory>? allCategories,
    List<DisplayCategory>? filteredCategories,
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
