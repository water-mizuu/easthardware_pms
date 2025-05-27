/// Wraps a stream factory and returns a stream of type T.
Stream<T> stream<T>(Stream<T> Function() factory) {
  return factory().cast<T>();
}
