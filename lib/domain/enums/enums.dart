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

enum InvoicePostAction {
  payment,
  create,
  none,
}

enum OrderType {
  restock,
  expense,
}
