import 'package:easthardware_pms/data/database/dao/orders_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/repository/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(DatabaseHelper? databaseHelper) : _ordersDao = OrdersDao(databaseHelper);

  final OrdersDao _ordersDao;

  @override
  Future<void> deleteOrder(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid order ID');
    }
    try {
      return await _ordersDao.deleteOrder(id);
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  @override
  Future<List<Order>> getAllOrders() async {
    try {
      return await _ordersDao.getAllOrders();
    } catch (e) {
      throw Exception('Failed to fetch all orders: $e');
    }
  }

  @override
  Future<Order?> getOrderById(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid order ID');
    }
    try {
      return await _ordersDao.getOrderById(id);
    } catch (e) {
      throw Exception('Failed to fetch order by ID: $e');
    }
  }

  @override
  Future<List<Order>> getOrdersByPayeeName(String payeeName) async {
    if (payeeName.isEmpty) {
      throw ArgumentError('Payee name cannot be empty');
    }
    try {
      return await _ordersDao.getOrdersByPayeeName(payeeName);
    } catch (e) {
      throw Exception('Failed to fetch orders by payee name: $e');
    }
  }

  @override
  Future<List<Order>> getOrdersByAmountDue(double minAmount, double maxAmount) async {
    if (minAmount < 0 || maxAmount < 0) {
      throw ArgumentError('Invalid amount range');
    }
    try {
      return await _ordersDao.getOrdersByAmountDue(minAmount, maxAmount);
    } catch (e) {
      throw Exception('Failed to fetch orders by amount due: $e');
    }
  }

  @override
  Future<List<Order>> getOrdersByCreatorId(int creatorId) async {
    if (creatorId <= 0) {
      throw ArgumentError('Invalid creator ID');
    }
    try {
      return await _ordersDao.getOrdersByCreatorId(creatorId);
    } catch (e) {
      throw Exception('Failed to fetch orders by creator ID: $e');
    }
  }

  @override
  Future<List<Order>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    if (startDate.isAfter(endDate)) {
      throw ArgumentError('Start date cannot be after end date');
    }
    try {
      return await _ordersDao.getOrdersByDateRange(startDate, endDate);
    } catch (e) {
      throw Exception('Failed to fetch orders by date range: $e');
    }
  }

  @override
  Future<List<Order>> getOrdersByExpenseType(int expenseType) async {
    if (expenseType <= 0) {
      throw ArgumentError('Invalid expense type');
    }
    try {
      return await _ordersDao.getOrdersByExpenseType(expenseType);
    } catch (e) {
      throw Exception('Failed to fetch orders by expense type: $e');
    }
  }

  @override
  Future<List<Order>> getOrdersByPaymentMethod(int paymentMethod) async {
    if (paymentMethod <= 0) {
      throw ArgumentError('Invalid payment method');
    }
    try {
      return await _ordersDao.getOrdersByPaymentMethod(paymentMethod);
    } catch (e) {
      throw Exception('Failed to fetch orders by payment method: $e');
    }
  }

  @override
  Future<List<Order>> getOrdersByProductNames(List<String> productNames) async {
    if (productNames.isEmpty) {
      throw ArgumentError('Product names cannot be empty');
    }
    try {
      return await _ordersDao.getOrdersByProductNames(productNames);
    } catch (e) {
      throw Exception('Failed to fetch orders by product names: $e');
    }
  }

  @override
  Future<int> getTotalAmountDue() async {
    try {
      return await _ordersDao.getTotalAmountDue();
    } catch (e) {
      throw Exception('Failed to fetch total amount due: $e');
    }
  }

  @override
  Future<int> getTotalOrderCount() async {
    try {
      return await _ordersDao.getTotalOrderCount();
    } catch (e) {
      throw Exception('Failed to fetch total order count: $e');
    }
  }

  @override
  Future<Order> insertOrder(Order order) async {
    try {
      return await _ordersDao.insertOrder(order);
    } catch (e) {
      throw Exception('Failed to insert order: $e');
    }
  }

  @override
  Future<Order> updateOrder(Order order) async {
    try {
      return await _ordersDao.updateOrder(order);
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }
}
