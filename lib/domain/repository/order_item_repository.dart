import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/order_item_repository.dart';
import 'package:easthardware_pms/domain/models/order_item.dart';

abstract class OrderItemRepository {
  factory OrderItemRepository(DatabaseHelper? databaseHelper) = OrderItemRepositoryImpl;

  Future<List<OrderItem>> getAllOrderItems();
  Future<OrderItem?> getOrderItemById(int id);
  Future<OrderItem> insertOrderItem(OrderItem OrderItem);
  Future<OrderItem> updateOrderItem(OrderItem OrderItem);
  Future<void> deleteOrderItem(int id);
  Future<List<OrderItem>> getOrderItemByOrderId(int orderId);
}
