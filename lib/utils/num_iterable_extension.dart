extension NumIterableExtension<N extends num> on Iterable<N> {
  N sum() => isEmpty
      ? ((N == int
          ? 0
          : N == double
              ? 0.0
              : 0) as N)
      : reduce((a, b) => a + b as N);
}
