extension type const ImmutableListView<T>(List<T> items) implements Iterable<T> {
  int get length => items.length;
  T operator [](int index) => items[index];

  Never take(int count) =>
      throw UnsupportedError('ImmutableListView does not support take operation');
}
