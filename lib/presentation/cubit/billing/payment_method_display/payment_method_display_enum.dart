import 'package:easthardware_pms/domain/models/payment_method.dart';

enum PaymentMethodDisplaySortBy {
  nameAscending('Name Ascending'),
  nameDescending('Name Descending');

  const PaymentMethodDisplaySortBy(this.name);
  final String name;

  int comparePaymentMethods(PaymentMethod a, PaymentMethod b) {
    switch (this) {
      case PaymentMethodDisplaySortBy.nameAscending:
        return a.name.compareTo(b.name);
      case PaymentMethodDisplaySortBy.nameDescending:
        return b.name.compareTo(a.name);
    }
  }
}
