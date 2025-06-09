enum DiscountType {
  percentage,
  value,
}

enum AccessLevel {
  staff,
  administrator;

  @override
  String toString() => switch (this) {
        staff => 'Staff',
        administrator => 'Administrator',
      };
}

enum DataStatus {
  initial,
  loading,
  success,
  error,
}

enum FormStatus {
  initial,
  validating,
  invalid,
  valid,
  submitting,
  submitted,
  error,
  loading,
  success,
}

enum PaymentMethod {
  cash,
  credit,
  gcash,
}
