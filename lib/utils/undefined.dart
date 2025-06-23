const undefined = #UndefinedValue;

extension UndefinedMethod on Object? {
  T or<T>(T value) {
    if (this == undefined) {
      return value;
    }
    return this as T;
  }

  @pragma('vm:prefer-inline')
  WeakReference<T> orWeakReference<T extends Object>(WeakReference<T> value) {
    if (this == undefined) {
      return value;
    }
    return WeakReference<T>(this as T);
  }
}
