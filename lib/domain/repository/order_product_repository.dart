import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/repository/order_product_repository.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';

abstract class OrderProductRepository {
  factory OrderProductRepository(DatabaseHelper? databaseHelper) = OrderProductRepositoryImpl;

  Future<List<OrderProduct>> getAllOrderProducts();
  Future<OrderProduct?> getOrderProductById(int id);
  Future<OrderProduct> insertOrderProduct(OrderProduct orderProduct);
  Future<OrderProduct> updateOrderProduct(OrderProduct orderProduct);
  Future<void> deleteOrderProduct(int id);
  Future<List<OrderProduct>> getOrderProductsByOrderId(int orderId);
}
