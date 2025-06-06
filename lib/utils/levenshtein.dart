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
      }

      final temp = v0;
      v0.setAll(0, v1);
      v1.setAll(0, temp);
    }

    return v0[b.length].toDouble();
  }
}
