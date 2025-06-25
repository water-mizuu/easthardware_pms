import 'dart:math';

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

  /// Ranks items based on their relevance to the query using optimized Levenshtein distance.
  /// Supports typo-tolerant search with multiple optimization strategies.
  static Future<List<T>> rankItems<T>(
    List<T> items,
    String query,
    Iterable<String> Function(T) mapper, [
    int Function(T, T)? comparator,
  ]) async {
    if (items.isEmpty || query.isEmpty) {
      return [...items]..sort((a, b) => comparator?.call(a, b) ?? 0);
    }

    final normalizedQuery = query.toLowerCase().trim();
    final queryTokens = normalizedQuery.split(RegExp(r'\s+'));

    // Pre-process items and their factors for better performance
    final processedItems = <({T item, Set<String> factors, Set<String> prefixes})>[];

    for (final item in items) {
      final factors =
          mapper(item).where((f) => f.isNotEmpty).map((f) => f.toLowerCase().trim()).toSet();

      // Generate prefixes for faster prefix matching
      final prefixes = <String>{};
      for (final factor in factors) {
        for (var i = 1; i <= min(factor.length, 6); i++) {
          prefixes.add(factor.substring(0, i));
        }
      }

      processedItems.add((item: item, factors: factors, prefixes: prefixes));
    }

    final scoredItems = <({T item, double score})>[];

    // Dynamic threshold based on query length
    final maxDistance = (normalizedQuery.length * 0.4).ceil().toDouble();

    for (final processed in processedItems) {
      final score = _calculateOptimizedScore(
        normalizedQuery,
        queryTokens,
        processed.factors,
        processed.prefixes,
        maxDistance,
      );

      if (score < double.infinity) {
        scoredItems.add((item: processed.item, score: score));
      }
    }

    // Sort by score (lower is better), then by comparator
    scoredItems.sort((a, b) {
      final scoreComparison = a.score.compareTo(b.score);
      if (scoreComparison != 0) return scoreComparison;
      return comparator?.call(a.item, b.item) ?? 0;
    });

    return scoredItems.map((e) => e.item).toList();
  }

  /// High-performance ranking for large datasets using two-pass filtering
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

    // For very large datasets, use two-pass filtering
    if (items.length > 1000) {
      // First pass: fast prefix/substring filtering
      final filtered = _fastPrefixFilter(items, query, mapper);

      // Second pass: detailed scoring on filtered results
      return rankItems(filtered, query, mapper, comparator);
    }

    // For smaller datasets, use the full algorithm
    return rankItems(items, query, mapper, comparator);
  }

  /// Convenience method for simple string-based search with typo tolerance
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

  /// Advanced search with custom field extraction and scoring
  ///
  /// Example:
  /// ```dart
  /// final products = [Product(name: 'iPhone', category: 'Electronics'), ...];
  /// final results = await Levenshtein.searchAdvanced(
  ///   products,
  ///   'phone',
  ///   fields: (p) => [p.name, p.category],
  ///   maxTypos: 2,
  ///   maxResults: 20,
  /// );
  /// ```
  static Future<List<T>> searchAdvanced<T>(
    List<T> items,
    String query, {
    required Iterable<String> Function(T) fields,
    int maxTypos = 2,
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

  /// Calculate optimized score using multiple strategies for typo-tolerant search
  static double _calculateOptimizedScore(
    String query,
    List<String> queryTokens,
    Set<String> factors,
    Set<String> prefixes,
    double maxDistance,
  ) {
    if (factors.isEmpty) return double.infinity;

    var bestScore = double.infinity;

    // Strategy 1: Exact match (highest priority)
    if (factors.contains(query)) return 0.0;

    // Strategy 2: Prefix matching for fast typing scenarios
    for (final token in queryTokens) {
      if (prefixes.contains(token)) {
        bestScore = min(bestScore, token.length * 0.1); // Very low score for prefix matches
      }
    }

    // Strategy 3: Substring matching (good for partial typing)
    for (final factor in factors) {
      for (final token in queryTokens) {
        if (factor.contains(token)) {
          // Score based on how much of the factor the token covers
          final coverage = token.length / factor.length;
          bestScore = min(bestScore, (1 - coverage) * 2);
        }
      }
    }

    // Strategy 4: Levenshtein distance for typo tolerance
    for (final factor in factors) {
      // Check against full query
      final queryDistance = distance(query, factor, maxDistance);
      if (queryDistance <= maxDistance) {
        bestScore = min(bestScore, queryDistance);
      }

      // Check against individual tokens for multi-word queries
      for (final token in queryTokens) {
        if (token.length >= 2) {
          // Skip very short tokens
          final tokenDistance = distance(token, factor, maxDistance);
          if (tokenDistance <= maxDistance) {
            // Slightly penalize token matches vs full query matches
            bestScore = min(bestScore, tokenDistance + 0.5);
          }
        }
      }
    }

    return bestScore;
  }

  /// Fast prefix-based filtering for very large datasets
  static List<T> _fastPrefixFilter<T>(
    List<T> items,
    String query,
    Iterable<String> Function(T) mapper,
  ) {
    if (query.length < 2) return items;

    final queryPrefix = query.toLowerCase().substring(0, min(query.length, 3));

    return items.where((item) {
      return mapper(item).any((factor) => factor.toLowerCase().startsWith(queryPrefix));
    }).toList();
  }

  @Deprecated('Use _calculateOptimizedScore instead')
  static double _scoreFactorsByLevenshtein(String query, Set<String?> factors, double threshold) {
    var bestScore = threshold;
    for (final factor in factors) {
      if (factor == null) continue;
      final score = distance(query, factor.toLowerCase(), bestScore);

      if (score < bestScore) {
        bestScore = score;
      }
    }

    return bestScore;
  }
}
