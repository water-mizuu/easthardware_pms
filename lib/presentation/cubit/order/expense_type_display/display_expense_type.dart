import 'package:easthardware_pms/domain/models/expense_type.dart';

class DisplayExpenseType {
  factory DisplayExpenseType.fromExpenseType(
    ExpenseType expenseType, {
    int orderCount = 0,
  }) {
    return DisplayExpenseType(
      expenseType: expenseType,
      orderCount: orderCount,
    );
  }

  const DisplayExpenseType({
    required this.expenseType,
    this.orderCount = 0,
  });
  final ExpenseType expenseType;
  final int orderCount;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisplayExpenseType &&
        other.expenseType.id == expenseType.id &&
        other.orderCount == orderCount;
  }

  @override
  int get hashCode => expenseType.id.hashCode ^ orderCount.hashCode;
}
