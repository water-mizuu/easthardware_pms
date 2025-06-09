extension ZipExtension<T> on Iterable<T> {
  /// Zips two iterables together into a list of pairs.
  ///
  /// If the two iterables are of different lengths, the resulting list will
  /// be as long as the shorter iterable.
  Iterable<(T, R)> zip<R>(Iterable<R> other) sync* {
    final iterator1 = iterator;
    final iterator2 = other.iterator;

    while (iterator1.moveNext() && iterator2.moveNext()) {
      yield (iterator1.current, iterator2.current);
    }
  }
}
