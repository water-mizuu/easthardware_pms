import 'dart:async';

import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/search/search_state.dart';
import 'package:easthardware_pms/utils/levenshtein.dart';
import 'package:easthardware_pms/utils/zip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(List<Product> allProducts) //
      : super(SearchState(allProducts: allProducts));

  void updateQuery(String query) {
    final lowercaseQuery = query.trim().toLowerCase();

    emit(state.copyWith(query: lowercaseQuery));

    /// Do the search logic here.
    ///   For now only search the products.
    if (lowercaseQuery.isEmpty) {
      updateResults(const SearchResults.empty());
      return;
    }
    _processQuery(lowercaseQuery);
  }

  Future<List<(Product, double)>> _processProduct(String query) async {
    final products = state.allProducts;
    final factors = products.map((p) => {p.sku, p.name, p.categoryName, p.description});

    final productScoreMap = <Product, double>{};
    var threshold = double.infinity;
    for (final (product, factor) in products.zip(factors)) {
      final score = _scoreFactors(query, factor, threshold);
      productScoreMap[product] = score;

      if (score > 0 && score < threshold) {
        threshold = score * 1.5; // Adjust threshold to allow for some flexibility
      }
    }

    final results = (productScoreMap.entries
            // .where((entry) => entry.value < threshold) //
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value)))
        .map((entry) => (entry.key, entry.value))
        .toList();

    return results;
  }

  Future<void> _processQuery(String query) async {
    setLoading(true);
    try {
      final products = await _processProduct(query);

      updateResults(SearchResults(
        products: products,
        invoices: [],
        orders: [],
      ));
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  void updateResults(SearchResults results) {
    emit(state.copyWith(results: results));
  }

  void setLoading(bool isLoading) {
    emit(state.copyWith(isLoading: isLoading));
  }

  void setError(String? errorMessage) {
    emit(state.copyWith(errorMessage: errorMessage));
  }

  double _scoreFactors(String query, Set<String?> factors, double threshold) {
    var bestScore = threshold;
    for (final factor in factors) {
      if (factor == null) continue; // Skip null factors
      final score = Levenshtein.distance(query, factor.toLowerCase(), bestScore);

      if (score < bestScore) {
        bestScore = score.toDouble();
      }
    }
    return bestScore;
  }
}
