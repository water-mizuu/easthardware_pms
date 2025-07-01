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
  printing,
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

enum CategoryDisplaySortBy {
  nameAscending('Name (A-Z)'),
  nameDescending('Name (Z-A)'),
  productCountAscending('Product Count (Low to High)'),
  productCountDescending('Product Count (High to Low)');

  const CategoryDisplaySortBy(this.name);
  final String name;

  @override
  String toString() => name;
}

enum PaymentDisplaySortBy {
  dateAscending('Date (Newest First)'),
  dateDescending('Date (Oldest First)'),
  customerAscending('Customer (A-Z)'),
  customerDescending('Customer (Z-A)'),
  amountAscending('Amount (Low to High)'),
  amountDescending('Amount (High to Low)'),
  referenceAscending('Reference (A-Z)'),
  referenceDescending('Reference (Z-A)');

  const PaymentDisplaySortBy(this.name);
  final String name;

  @override
  String toString() => name;
}

enum InvoiceDisplaySortBy {
  invoiceDateAscending('Date (Newest First)'),
  invoiceDateDescending('Date (Oldest First)'),
  numberAscending('Invoice Number (Low to High)'),
  numberDescending('Invoice Number (High to Low)'),
  customerAscending('Customer (A-Z)'),
  customerDescending('Customer (Z-A)'),
  totalAscending('Total (Low to High)'),
  totalDescending('Total (High to Low)'),
  statusAscending('Status (A-Z)'),
  statusDescending('Status (Z-A)');

  const InvoiceDisplaySortBy(this.name);
  final String name;

  @override
  String toString() => name;
}
