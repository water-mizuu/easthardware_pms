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
  submitting,
  submitted,
  invalid,
  error,
  loading,
  success,
}

enum PaymentMethod {
  cash,
  credit,
  gcash,
}

enum InvoicePostAction {
  payment,
  create,
  none,
}
