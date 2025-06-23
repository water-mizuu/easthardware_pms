import 'package:easthardware_pms/data/database/dao/order_products_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/repository/order_product_repository.dart';

class OrderProductRepositoryImpl implements OrderProductRepository {
  OrderProductRepositoryImpl(DatabaseHelper? databaseHelper)
      : _orderProductsDao = OrderProductsDao(databaseHelper);

  final OrderProductsDao _orderProductsDao;

  @override
  Future<void> deleteOrderProduct(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid order product ID');
    }
    try {
      return await _orderProductsDao.deleteOrderProduct(id);
    } catch (e) {
      throw DatabaseException('Failed to delete order product: $e');
    }
  }

  @override
  Future<List<OrderProduct>> getAllOrderProducts() async {
    try {
      return await _orderProductsDao.getAllOrderProducts();
    } catch (e) {
      throw DatabaseException('Failed to fetch all order products: $e');
    }
  }

  @override
  Future<OrderProduct?> getOrderProductById(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid order product ID');
    }
    try {
      return await _orderProductsDao.getOrderProductById(id);
    } catch (e) {
      throw DatabaseException('Failed to fetch order product by ID: $e');
    }
  }

  @override
  Future<List<OrderProduct>> getOrderProductsByOrderId(int orderId) async {
    if (orderId <= 0) {
      throw ArgumentError('Invalid order ID');
    }
    try {
      return await _orderProductsDao.getOrderProductsByOrderId(orderId);
    } catch (e) {
      throw DatabaseException('Failed to fetch order products by order ID: $e');
    }
  }

  @override
  Future<OrderProduct> insertOrderProduct(OrderProduct orderProduct) async {
    _validateOrderProduct(orderProduct);
    try {
      return await _orderProductsDao.insertOrderProduct(orderProduct);
    } catch (e) {
      throw DatabaseException('Failed to insert order product: $e');
    }
  }

  @override
  Future<OrderProduct> updateOrderProduct(OrderProduct orderProduct) async {
    _validateOrderProduct(orderProduct);
    try {
      return await _orderProductsDao.updateOrderProduct(orderProduct);
    } catch (e) {
      throw DatabaseException('Failed to update order product: $e');
    }
  }

  @override
  Future<void> deleteOrderProductsByOrderId(int orderId) async {
    if (orderId <= 0) {
      throw ArgumentError('Invalid order ID');
    }
    try {
      await _orderProductsDao.deleteOrderProductsByOrderId(orderId);
    } catch (e) {
      throw DatabaseException('Failed to delete order products for order: $e');
    }
  }

  void _validateOrderProduct(OrderProduct orderProduct) {
    if (orderProduct.quantity <= 0) {
      throw ArgumentError('Quantity should be greater than 0');
    }
    if (orderProduct.productName.isEmpty) {
      throw ArgumentError('Please select a product');
    }
    if (orderProduct.rate <= 0) {
      throw ArgumentError('Unit price should be greater than 0');
    }
  }
}
