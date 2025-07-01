import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/utils/compare_lowercase.dart';

enum PaymentMethodDisplaySortBy {
  nameAscending('Name (A-Z)'),
  nameDescending('Name (Z-A)');

  const PaymentMethodDisplaySortBy(this.name);
  final String name;

  int comparePaymentMethods(PaymentMethod a, PaymentMethod b) {
    switch (this) {
      case PaymentMethodDisplaySortBy.nameAscending:
        return a.name.compareToLowercase(b.name);
      case PaymentMethodDisplaySortBy.nameDescending:
        return b.name.compareToLowercase(a.name);
    }
  }
}
