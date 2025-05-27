extension TryFutureExtension<T> on Future<T> {
  /// Attempts to complete the future, returning the result if successful,
  /// or null if an error occurs.
  Future<(T?, (Object, StackTrace)?)> tryCatch() async {
    try {
      return (await this, null);
    } catch (e, stackTrace) {
      return (null, (e, stackTrace));
    }
  }
}
