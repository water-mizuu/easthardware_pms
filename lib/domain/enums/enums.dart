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
  nameAscending('Name Ascending'),
  nameDescending('Name Descending'),
  productCountAscending('Product Count Ascending'),
  productCountDescending('Product Count Descending');

  const CategoryDisplaySortBy(this.name);
  final String name;

  @override
  String toString() => name;
}

enum PaymentDisplaySortBy {
  dateAscending('Date Ascending'),
  dateDescending('Date Descending'),
  amountAscending('Amount Ascending'),
  amountDescending('Amount Descending'),
  referenceAscending('Reference Ascending'),
  referenceDescending('Reference Descending');

  const PaymentDisplaySortBy(this.name);
  final String name;

  @override
  String toString() => name;
}

enum InvoiceDisplaySortBy {
  invoiceDateAscending('Date Ascending'),
  invoiceDateDescending('Date Descending'),
  numberAscending('Invoice Number Ascending'),
  numberDescending('Invoice Number Descending'),
  customerAscending('Customer Ascending'),
  customerDescending('Customer Descending'),
  totalAscending('Total Ascending'),
  totalDescending('Total Descending'),
  statusAscending('Status Ascending'),
  statusDescending('Status Descending');

  const InvoiceDisplaySortBy(this.name);
  final String name;

  @override
  String toString() => name;
}
