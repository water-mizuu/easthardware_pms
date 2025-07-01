import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/utils/compare_lowercase.dart';

enum OrderDisplaySortBy {
  orderDateAscending,
  orderDateDescending,
  idAscending,
  idDescending,
  payeeNameAscending,
  payeeNameDescending,
  expenseTypeAscending,
  expenseTypeDescending,
  amountDueAscending,
  amountDueDescending;

  int Function(Order a, Order b) get compareOrders {
    switch (this) {
      case OrderDisplaySortBy.orderDateAscending:
        return (a, b) => a.orderDate.compareTo(b.orderDate);
      case OrderDisplaySortBy.orderDateDescending:
        return (a, b) => b.orderDate.compareTo(a.orderDate);
      case OrderDisplaySortBy.idAscending:
        return (a, b) => a.id!.compareTo(b.id!);
      case OrderDisplaySortBy.idDescending:
        return (a, b) => b.id!.compareTo(a.id!);
      case OrderDisplaySortBy.payeeNameAscending:
        return (a, b) => a.payeeName.compareToLowercase(b.payeeName);
      case OrderDisplaySortBy.payeeNameDescending:
        return (a, b) => b.payeeName.compareToLowercase(a.payeeName);
      case OrderDisplaySortBy.expenseTypeAscending:
        return (a, b) => a.expenseType.compareTo(b.expenseType);
      case OrderDisplaySortBy.expenseTypeDescending:
        return (a, b) => b.expenseType.compareTo(a.expenseType);
      case OrderDisplaySortBy.amountDueAscending:
        return (a, b) => a.amountDue.compareTo(b.amountDue);
      case OrderDisplaySortBy.amountDueDescending:
        return (a, b) => b.amountDue.compareTo(a.amountDue);
    }
  }
}
