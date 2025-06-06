import 'dart:isolate';
import 'dart:math';

final class Levenshtein {
  /// We make the constructor private to prevent instantiation.
  const Levenshtein._();

  ///
  static double distance(String a, String b, [double maximum = double.infinity]) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length.toDouble();
    if (b.isEmpty) return a.length.toDouble();

    final v0 = List<int>.generate(b.length + 1, (i) => i);
    final v1 = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      v1[0] = i;

      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;

        v1[j] = min(
          v0[j] + 1, // Deletion
          min(
            v1[j - 1] + 1, // Insertion
            v0[j - 1] + cost, // Substitution
          ),
        );

        if (v1[j] > maximum) {
          return maximum + 1; // Early exit if the distance exceeds the maximum
        }
      }

      final temp = v0;
      v0.setAll(0, v1);
      v1.setAll(0, temp);
    }

    return v0[b.length].toDouble();
  }

  /// Ranks items base on their relevance to the query using Levenshtein distance.
  static Future<List<T>> rankItems<T>(
    List<T> items,
    String query,
    Iterable<String> Function(T) mapper,
  ) {
    return Isolate.run(() {
      if (items.isEmpty || query.isEmpty) {
        return items; // Return the original list if empty or query is empty
      }

      /// This should contain the items that are being ranked.
      final itemScoreMap = <T, double>{};
      final tokens = query.toLowerCase().split(RegExp(r'\s+'));

      /// The threshold is strictly decreasing as the items are processed.
      ///   It starts at infinity and is adjusted based on the scores of the items.
      var threshold = double.infinity;
      for (final (item, factor) in items.map((c) => (c, mapper(c).toSet()))) {
        var score = _scoreFactorsByLevenshtein(query, factor, threshold);

        /// If any of the tokens have a direct match with the factor,
        ///   we reduce the score even more.
        if (tokens.any(factor.contains)) {
          score = sqrt(score);
        }

        // Skip if the score is not better than the existing one
        if (itemScoreMap[item] case final existing? when existing <= score) continue;

        itemScoreMap[item] = score;
        if ((score + 1) * 2 < threshold) {
          threshold = (score + 1) * 2; // Adjust threshold to allow for some flexibility
        }
      }

      final results = (itemScoreMap.entries
              .where((entry) => entry.value < threshold) //
              .toList()
            ..sort((a, b) => a.value.compareTo(b.value)))
          .map((entry) => entry.key)
          .toList();

      return results.toList();
    });
  }

  static double _scoreFactorsByLevenshtein(String query, Set<String?> factors, double threshold) {
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
