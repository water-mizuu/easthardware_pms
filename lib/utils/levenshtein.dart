import 'dart:math';

import 'package:easthardware_pms/utils/boxed.dart';

final class Levenshtein {
  /// We make the constructor private to prevent instantiation.
  const Levenshtein._();

  /// Optimized distance calculation with early termination
  static double distance(String a, String b, [double? maximum]) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length.toDouble();
    if (b.isEmpty) return a.length.toDouble();

    // Ensure a is the shorter string for optimization
    if (a.length > b.length) {
      final temp = a;
      a = b;
      b = temp;
    }

    final aLen = a.length;
    final bLen = b.length;

    // Set maximum to a reasonable value if not provided
    maximum ??= max(aLen, bLen).toDouble();

    // Early exit if length difference exceeds maximum
    if ((bLen - aLen) > maximum) return maximum + 1;

    // Use single array optimization (Wagner-Fischer algorithm)
    var previousRow = List<int>.generate(bLen + 1, (i) => i);
    var currentRow = List<int>.filled(bLen + 1, 0);

    for (var i = 1; i <= aLen; i++) {
      currentRow[0] = i;
      var minInRow = i;

      for (var j = 1; j <= bLen; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;

        currentRow[j] = min(
          previousRow[j] + 1, // deletion
          min(
            currentRow[j - 1] + 1, // insertion
            previousRow[j - 1] + cost, // substitution
          ),
        );

        minInRow = min(minInRow, currentRow[j]);
      }

      // Early termination if minimum in current row exceeds maximum
      if (minInRow > maximum) return maximum + 1;

      // Swap arrays
      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }

    return previousRow[bLen].toDouble();
  }

  /// Ranks items based on their relevance to the query using Levenshtein distance and exact matches.
  static List<T> rankItems<T>(
    List<T> itemsToSort,
    String query,
    Iterable<String> Function(T) mapper, [
    int Function(T, T)? comparator,
  ]) {
    if (itemsToSort.isEmpty || query.isEmpty) {
      return [...itemsToSort]..sort((a, b) => comparator?.call(a, b) ?? 0);
    }

    final normalizedQuery = query.toLowerCase().trim();
    final tokenizedQuery = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .followedBy([normalizedQuery]).toList();
    final scoredItems = <({T item, double score})>[];

    for (final item in itemsToSort) {
      final factors = mapper(item).where((f) => f.isNotEmpty).map((f) => f.toLowerCase().trim());
      var bestScore = double.infinity;

      for (final factor in factors) {
        // Check for exact match first (score = 0)
        if (factor == normalizedQuery) {
          bestScore = 0.0;
          break;
        }

        // Calculate Levenshtein distance
        final levenshteinScore = tokenizedQuery //
            .map((f) => distance(factor, f))
            .reduce((a, b) => min(a, b));

        if (levenshteinScore < bestScore) {
          bestScore = levenshteinScore;
        }
      }

      if (bestScore < double.infinity) {
        scoredItems.add((item: item, score: bestScore));
      }
    }

    // Sort by score (lower is better), then by comparator
    scoredItems.sort((a, b) {
      final scoreComparison = a.score.compareTo(b.score);
      if (scoreComparison != 0) return scoreComparison;
      return comparator?.call(a.item, b.item) ?? 0;
    });

    printBoxed((tokenizedQuery, scoredItems));

    return scoredItems.map((e) => e.item).toList();
  }

  /// High-performance ranking for large datasets using simplified Levenshtein distance
  static Future<List<T>> rankItemsFast<T>(
    List<T> items,
    String query,
    Iterable<String> Function(T) mapper, [
    int Function(T, T)? comparator,
    int maxResults = 100,
  ]) async {
    if (items.isEmpty || query.isEmpty) {
      return [...items]..sort((a, b) => comparator?.call(a, b) ?? 0);
    }

    // Use the simplified ranking algorithm for all cases
    final results = rankItems(items, query, mapper, comparator);
    return results.take(maxResults).toList();
  }

  /// Convenience method for simple string-based search using Levenshtein distance
  ///
  /// Example:
  /// ```dart
  /// final users = ['John Doe', 'Jane Smith', 'Bob Johnson'];
  /// final results = await Levenshtein.searchStrings(users, 'jon');
  /// // Returns: ['John Doe', 'Bob Johnson'] (sorted by relevance)
  /// ```
  static Future<List<String>> searchStrings(
    List<String> items,
    String query, [
    int maxResults = 50,
  ]) async {
    final results = await rankItemsFast(
      items,
      query,
      (item) => [item],
      null,
      maxResults,
    );

    return results.take(maxResults).toList();
  }

  /// Advanced search using Levenshtein distance and exact matching
  ///
  /// Example:
  /// ```dart
  /// final products = [Product(name: 'iPhone', category: 'Electronics'), ...];
  /// final results = await Levenshtein.searchAdvanced(
  ///   products,
  ///   'phone',
  ///   fields: (p) => [p.name, p.category],
  ///   maxResults: 20,
  /// );
  /// ```
  static Future<List<T>> searchAdvanced<T>(
    List<T> items,
    String query, {
    required Iterable<String> Function(T) fields,
    int maxResults = 100,
    int Function(T, T)? comparator,
  }) async {
    final results = await rankItemsFast(
      items,
      query,
      fields,
      comparator,
      maxResults,
    );

    return results.take(maxResults).toList();
  }
}
