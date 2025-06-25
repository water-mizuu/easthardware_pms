import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'category_display_state.dart';

class CategoryDisplayCubit extends Cubit<CategoryDisplayState> {
  CategoryDisplayCubit() : super(CategoryDisplayState.empty()) {
    // Initialize any listeners or subscriptions if needed
  }

  // Method to update the list of categories
  void updateCategories(List<DisplayCategory> categories) {
    if (categories.isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        filteredCategories: null,
        allCategories: null,
      ));
      return;
    }

    emit(state.copyWith(allCategories: categories));
    _processQuery();
  }

  // Method to update search query
  void search(String query) {
    final allCategories = state.allCategories;
    if (allCategories == null || allCategories.isEmpty) {
      emit(state.copyWith(
        searchQuery: query,
        allCategories: null,
      ));
      return;
    }

    emit(state.copyWith(searchQuery: query));
    _processQuery();
  }

  // Method to update sort criteria
  void sort(CategoryDisplaySortBy sortBy, [List<int>? products]) {
    // Check if we're selecting the same sort type that's already active
    if (state.sortBy == sortBy) {
      // Toggle the sort direction if the same sort type is selected again
      emit(state.copyWith(sortAscending: !state.sortAscending));

      // Determine the appropriate sort type based on the field and direction
      final newSortBy = _getSortTypeBasedOnDirection(sortBy, !state.sortAscending);

      emit(state.copyWith(sortBy: newSortBy));
    } else {
      // Default to ascending order for new sort type
      emit(state.copyWith(
        sortBy: sortBy,
        sortAscending: true,
      ));
    }

    _processQuery(products);
  }

  // Helper method to get the correct sort type based on direction
  CategoryDisplaySortBy _getSortTypeBasedOnDirection(
    CategoryDisplaySortBy sortType,
    bool ascending,
  ) {
    switch (sortType) {
      case CategoryDisplaySortBy.nameAscending:
      case CategoryDisplaySortBy.nameDescending:
        return ascending
            ? CategoryDisplaySortBy.nameAscending
            : CategoryDisplaySortBy.nameDescending;

      case CategoryDisplaySortBy.productCountAscending:
      case CategoryDisplaySortBy.productCountDescending:
        return ascending
            ? CategoryDisplaySortBy.productCountAscending
            : CategoryDisplaySortBy.productCountDescending;

      default:
        return CategoryDisplaySortBy.nameAscending;
    }
  }

  // Process the query and filter/sort the categories
  void _processQuery([List<int>? products]) {
    final allCategories = state.allCategories;
    if (allCategories == null || allCategories.isEmpty) {
      emit(state.copyWith(filteredCategories: null));
      return;
    }

    // First, filter by search query if needed
    final searchQuery = state.searchQuery.trim().toLowerCase();
    var filteredCategories = allCategories;

    if (searchQuery.isNotEmpty) {
      filteredCategories = allCategories.where((category) {
        final name = category.category.name.toLowerCase();

        // Simple contains check
        if (name.contains(searchQuery)) {
          return true;
        }

        // Levenshtein distance check for fuzzy matching
        final distance = Levenshtein.distance(name, searchQuery);
        final maxDistance = max(1, searchQuery.length ~/ 3);
        return distance <= maxDistance;
      }).toList();
    }

    // Then sort based on the selected sort criteria
    _sortCategories(filteredCategories, products);

    emit(state.copyWith(filteredCategories: filteredCategories));
  }

  // Helper method to sort categories
  void _sortCategories(List<DisplayCategory> categories, [List<int>? products]) {
    switch (state.sortBy) {
      case CategoryDisplaySortBy.nameAscending:
        categories.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
      case CategoryDisplaySortBy.nameDescending:
        categories.sort((a, b) => b.displayName.compareTo(a.displayName));
        break;
      case CategoryDisplaySortBy.productCountAscending:
        categories.sort((a, b) => a.productCount?.compareTo(b.productCount ?? 0) ?? 0);
        break;
      case CategoryDisplaySortBy.productCountDescending:
        // Same fallback as above
        categories.sort((a, b) => b.productCount?.compareTo(a.productCount ?? 0) ?? 0);
        break;
    }
  }
}
