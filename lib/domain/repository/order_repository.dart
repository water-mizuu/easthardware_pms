import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/order_repository.dart';
import 'package:easthardware_pms/domain/models/order.dart';

abstract class OrderRepository {
  factory OrderRepository(DatabaseHelper? databaseHelper) = OrderRepositoryImpl;

  Future<List<Order>> getAllOrders();
  Future<Order?> getOrderById(int id);
  Future<Order> insertOrder(Order order);
  Future<Order> updateOrder(Order order);
  Future<void> deleteOrder(int id);
  Future<List<Order>> getOrdersByPayeeName(String payeeName);
  Future<List<Order>> getOrdersByDateRange(DateTime startDate, DateTime endDate);
  Future<List<Order>> getOrdersByPaymentMethod(int paymentMethod);
  Future<List<Order>> getOrdersByAmountDue(double minAmount, double maxAmount);
  Future<List<Order>> getOrdersByCreatorId(int creatorId);
  Future<List<Order>> getOrdersByProductNames(List<String> productNames);
  Future<List<Order>> getOrdersByExpenseType(int expenseType);
  Future<int> getTotalAmountDue();
  Future<int> getTotalOrderCount();
}
