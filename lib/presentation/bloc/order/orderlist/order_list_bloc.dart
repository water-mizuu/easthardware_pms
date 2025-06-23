import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/order_item.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/repository/order_item_repository.dart';
import 'package:easthardware_pms/domain/repository/order_product_repository.dart';
import 'package:easthardware_pms/domain/repository/order_repository.dart';
import 'package:easthardware_pms/domain/repository/product_repository.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'order_list_event.dart';
part 'order_list_state.dart';

class OrderListBloc extends Bloc<OrderListEvent, OrderListState> {
  OrderListBloc(
    this._repository,
    this._orderProductRepository,
    this._orderItemRepository,
    this._productRepository, // Inject ProductRepository
    OrderListState initialState,
  ) : super(initialState) {
    on<FetchAllOrdersEvent>(_onFetchOrders);
    on<FetchOrderProductsEvent>(_onFetchOrderProducts);
    on<FetchOrderItemsEvent>(_onFetchOrderItems);
    on<AddProductOrderEvent>(_onAddProductOrder);
    on<AddItemOrderEvent>(_onAddItemOrder);
    on<UpdateOrderEvent>(_onUpdateOrder);
    on<DeleteOrderEvent>(_onDeleteOrder);
  }
  final OrderRepository _repository;
  final OrderProductRepository _orderProductRepository;
  final OrderItemRepository _orderItemRepository;
  final ProductRepository _productRepository;

  Future<void> _onFetchOrders(FetchAllOrdersEvent event, Emitter emit) async {
    print('[OrderListBloc] Fetching all orders...');
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final orders = await _repository.getAllOrders();
      final orderProducts = await _orderProductRepository.getAllOrderProducts();
      final orderItems = await _orderItemRepository.getAllOrderItems();

      print('[OrderListBloc] Orders fetched: count = \'${orders.length}\', orders = $orders');
      print('[OrderListBloc] Order products fetched: count = \'${orderProducts.length}\'');
      print('[OrderListBloc] Order items fetched: count = \'${orderItems.length}\'');

      emit(state.copyWith(
        allOrders: orders,
        allOrderProducts: orderProducts,
        allOrderItems: orderItems,
        status: DataStatus.success,
      ));
    } catch (e) {
      print('[OrderListBloc] Error fetching orders: $e');
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAddProductOrder(AddProductOrderEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final order = await _repository.insertOrder(event.order);
      print('[OrderListBloc] Inserted Order: ${order.id}, ${order.toMap()}');
      final products = event.products
          .map((product) => _orderProductRepository.insertOrderProduct(
                product.copyWith(orderId: order.id),
              ))
          .toList();
      final newlyAddedProducts = await Future.wait(products);
      // Update product stock: add quantity for each product

      print(
          '[OrderListBloc] Inserted products: ${newlyAddedProducts.map((i) => i.toMap()).toList()}');
      final updateStockFutures = event.products.map((product) {
        return _productRepository.updateProductStock(product.productId, product.quantity);
      }).toList();
      await Future.wait(updateStockFutures);

      // Fetch all orders to ensure we have the latest data
      final orders = await _repository.getAllOrders();
      final orderProducts = await _orderProductRepository.getAllOrderProducts();
      emit(state.copyWith(
        allOrders: orders,
        allOrderProducts: orderProducts,
        status: DataStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAddItemOrder(AddItemOrderEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final order = await _repository.insertOrder(event.order);
      if (kDebugMode) {
        print('[OrderListBloc] Inserted Order: ${order.id}, ${order.toMap()}');
      }
      if (kDebugMode) {
        print(
            '[OrderListBloc] Inserting Order Items: ${event.items.map((i) => i.toMap()).toList()}');
      }

      final newlyAddedItems = await event.items
          .map((i) => _orderItemRepository.insertOrderItem(i.copyWith(orderId: order.id!)))
          .toList()
          .wait;

      if (kDebugMode) {
        print(
          '[OrderListBloc] Newly Inserted Items: '
          '${newlyAddedItems.map((i) => i.toMap()).toList()}',
        );
      }

      // Fetch all orders to ensure we have the latest data
      final orders = await _repository.getAllOrders();
      final orderItems = await _orderItemRepository.getAllOrderItems();
      emit(state.copyWith(
        allOrders: orders,
        allOrderItems: orderItems,
        status: DataStatus.success,
      ));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[OrderListBloc] Error adding order items: $e');
      }
      if (kDebugMode) {
        print('[OrderListBloc] Stack trace: $stackTrace');
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onUpdateOrder(UpdateOrderEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      // Fetch the original order products to reverse their quantities
      final originalOrderProducts =
          await _orderProductRepository.getOrderProductsByOrderId(event.order.id!);

      // First, reverse the effects of the original order by updating product quantities
      // with negative values of the original quantities
      final reverseOriginalStockFutures = originalOrderProducts.map((product) {
        // We use negative quantity to subtract from current inventory
        return _productRepository.updateProductStock(product.productId, -product.quantity);
      }).toList();
      await Future.wait(reverseOriginalStockFutures);

      // Update the order
      await _repository.updateOrder(event.order);

      // Delete existing order products
      await _orderProductRepository.deleteOrderProductsByOrderId(event.order.id!);

      // Then insert the new order products
      final productFutures = event.products
          .map((product) => _orderProductRepository.insertOrderProduct(product))
          .toList();
      await Future.wait(productFutures);

      // Now add the new quantities to the inventory
      final updateStockFutures = event.products.map((product) {
        return _productRepository.updateProductStock(product.productId, product.quantity);
      }).toList();
      await Future.wait(updateStockFutures);

      // Update the orders list in the state
      final orders = state.allOrders.map((o) => o.id == event.order.id ? event.order : o).toList();
      emit(state.copyWith(allOrders: orders, status: DataStatus.success));
    } catch (e) {
      print('[OrderListBloc] Error updating order: $e');
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onDeleteOrder(DeleteOrderEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _repository.deleteOrder(event.order.id!);
      final orders = List<Order>.from(state.allOrders)..remove(event.order);
      emit(state.copyWith(allOrders: orders, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onFetchOrderProducts(FetchOrderProductsEvent event, Emitter emit) async {
    if (kDebugMode) {
      print('[OrderListBloc] Fetching order products...');
    }
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final orderProducts = await _orderProductRepository.getAllOrderProducts();
      if (kDebugMode) {
        print('[OrderListBloc] Order products fetched: count = \'${orderProducts.length}\'');
      }
      emit(state.copyWith(allOrderProducts: orderProducts, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print('[OrderListBloc] Error fetching order products: $e');
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onFetchOrderItems(FetchOrderItemsEvent event, Emitter emit) async {
    if (kDebugMode) {
      print('[OrderListBloc] Fetching order items...');
    }
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final orderItems = await _orderItemRepository.getAllOrderItems();
      if (kDebugMode) {
        print('[OrderListBloc] Order items fetched: count = \'${orderItems.length}\'');
      }
      emit(state.copyWith(allOrderItems: orderItems, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print('[OrderListBloc] Error fetching order items: $e');
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }
}
