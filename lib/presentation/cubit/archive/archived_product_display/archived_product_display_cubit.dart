import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/cubit/archive/archive_sort_enums.dart';
import 'package:equatable/equatable.dart';

part 'archived_product_display_state.dart';

class ArchivedProductDisplayCubit extends Cubit<ArchivedProductDisplayState> {
  ArchivedProductDisplayCubit() : super(const ArchivedProductDisplayState());

  void updateProducts(List<Product> products) {
    emit(state.copyWith(allProducts: products, filteredProducts: products));
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(filteredProducts: state.allProducts));
    } else {
      final filteredProducts = state.allProducts
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.sku.toLowerCase().contains(query.toLowerCase()) ||
              (product.categoryName?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
      emit(state.copyWith(filteredProducts: filteredProducts));
    }
  }

  void sort(ArchivedProductSortBy sortBy) {
    final products = List<Product>.from(state.filteredProducts);
    bool sortAscending = true;

    switch (sortBy) {
      case ArchivedProductSortBy.idAscending:
        products.sort((a, b) => a.id!.compareTo(b.id!));
        sortBy = ArchivedProductSortBy.idDescending;
        break;
      case ArchivedProductSortBy.idDescending:
        products.sort((a, b) => b.id!.compareTo(a.id!));
        sortBy = ArchivedProductSortBy.idAscending;
        sortAscending = false;
        break;
      case ArchivedProductSortBy.skuAscending:
        products.sort((a, b) => a.sku.compareTo(b.sku));
        sortBy = ArchivedProductSortBy.skuDescending;
        break;
      case ArchivedProductSortBy.skuDescending:
        products.sort((a, b) => b.sku.compareTo(a.sku));
        sortBy = ArchivedProductSortBy.skuAscending;
        sortAscending = false;
        break;
      case ArchivedProductSortBy.nameAscending:
        products.sort((a, b) => a.name.compareTo(b.name));
        sortBy = ArchivedProductSortBy.nameDescending;
        break;
      case ArchivedProductSortBy.nameDescending:
        products.sort((a, b) => b.name.compareTo(a.name));
        sortBy = ArchivedProductSortBy.nameAscending;
        sortAscending = false;
        break;
      case ArchivedProductSortBy.categoryAscending:
        products.sort((a, b) => (a.categoryName ?? '').compareTo(b.categoryName ?? ''));
        sortBy = ArchivedProductSortBy.categoryDescending;
        break;
      case ArchivedProductSortBy.categoryDescending:
        products.sort((a, b) => (b.categoryName ?? '').compareTo(a.categoryName ?? ''));
        sortBy = ArchivedProductSortBy.categoryAscending;
        sortAscending = false;
        break;
      case ArchivedProductSortBy.priceAscending:
        products.sort((a, b) => a.salePrice.compareTo(b.salePrice));
        sortBy = ArchivedProductSortBy.priceDescending;
        break;
      case ArchivedProductSortBy.priceDescending:
        products.sort((a, b) => b.salePrice.compareTo(a.salePrice));
        sortBy = ArchivedProductSortBy.priceAscending;
        sortAscending = false;
        break;
    }

    emit(state.copyWith(
      filteredProducts: products,
      sortBy: sortBy,
      sortAscending: sortAscending,
    ));
  }
}
