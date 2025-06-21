import 'package:easthardware_pms/data/database/dao/order_items_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/order_item.dart';
import 'package:easthardware_pms/domain/repository/order_item_repository.dart';

class OrderItemRepositoryImpl implements OrderItemRepository {
  OrderItemRepositoryImpl(DatabaseHelper? databaseHelper)
      : _orderItemsDao = OrderItemsDao(databaseHelper);

  final OrderItemsDao _orderItemsDao;

  @override
  Future<void> deleteOrderItem(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid order product ID');
    }
    try {
      return await _orderItemsDao.deleteOrderItem(id);
    } catch (e) {
      throw DatabaseException('Failed to delete order product: $e');
    }
  }

  @override
  Future<List<OrderItem>> getAllOrderItems() async {
    try {
      return await _orderItemsDao.getAllOrderItems();
    } catch (e) {
      throw DatabaseException('Failed to fetch all order products: $e');
    }
  }

  @override
  Future<OrderItem?> getOrderItemById(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid order product ID');
    }
    try {
      return await _orderItemsDao.getOrderItemById(id);
    } catch (e) {
      throw DatabaseException('Failed to fetch order product by ID: $e');
    }
  }

  @override
  Future<List<OrderItem>> getOrderItemByOrderId(int orderId) async {
    if (orderId <= 0) {
      throw ArgumentError('Invalid order ID');
    }
    try {
      return await _orderItemsDao.getOrderItemsByOrderId(orderId);
    } catch (e) {
      throw DatabaseException('Failed to fetch order products by order ID: $e');
    }
  }

  @override
  Future<OrderItem> insertOrderItem(OrderItem orderItem) async {
    _validateOrderProduct(orderItem);
    try {
      return await _orderItemsDao.insertOrderItem(orderItem);
    } catch (e) {
      throw DatabaseException('Failed to insert order product: $e');
    }
  }

  @override
  Future<OrderItem> updateOrderItem(OrderItem orderItem) async {
    _validateOrderProduct(orderItem);
    try {
      return await _orderItemsDao.updateOrderItem(orderItem);
    } catch (e) {
      throw DatabaseException('Failed to update order product: $e');
    }
  }

  void _validateOrderProduct(OrderItem orderItem) {
    if (orderItem.quantity <= 0) {
      throw ArgumentError('Quantity should be greater than 0');
    }
    if (orderItem.name.isEmpty) {
      throw ArgumentError('Please select a product');
    }
    if (orderItem.rate <= 0) {
      throw ArgumentError('Unit price should be greater than 0');
    }
  }
}
