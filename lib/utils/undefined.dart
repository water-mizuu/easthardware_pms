const undefined = #UndefinedValue;

extension UndefinedMethod on Object? {
  T or<T>(T value) {
    if (this == undefined) {
      return value;
    }
    return this as T;
  }
}
