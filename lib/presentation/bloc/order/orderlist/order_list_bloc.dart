import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/repository/order_repository.dart';
import 'package:easthardware_pms/domain/repository/order_product_repository.dart';
import 'package:easthardware_pms/domain/repository/product_repository.dart';
import 'package:equatable/equatable.dart';

part 'order_list_event.dart';
part 'order_list_state.dart';

class OrderListBloc extends Bloc<OrderListEvent, OrderListState> {
  OrderListBloc(
    this._repository,
    this.orderProductRepository,
    this.productRepository, // Inject ProductRepository
    OrderListState initialState,
  ) : super(initialState) {
    on<FetchAllOrdersEvent>(_onFetchOrders);
    on<AddOrderEvent>(_onAddOrder);
    on<UpdateOrderEvent>(_onUpdateOrder);
    on<DeleteOrderEvent>(_onDeleteOrder);
  }
  final OrderRepository _repository;
  final OrderProductRepository orderProductRepository;
  final ProductRepository productRepository;

  Future<void> _onFetchOrders(FetchAllOrdersEvent event, Emitter emit) async {
    print('[OrderListBloc] Fetching all orders...');
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final orders = await _repository.getAllOrders();
      print(
          '[OrderListBloc] Orders fetched: count = \'${orders.length}\', orders = $orders');
      emit(state.copyWith(allOrders: orders, status: DataStatus.success));
    } catch (e) {
      print('[OrderListBloc] Error fetching orders: $e');
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAddOrder(AddOrderEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final order = await _repository.insertOrder(event.order);
      final products = event.products
          .map((product) => orderProductRepository.insertOrderProduct(
                product.copyWith(orderId: order.id),
              ))
          .toList();
      await Future.wait(products);
      // Update product stock: add quantity for each product
      final updateStockFutures = event.products.map((product) {
        return productRepository.updateProductStock(
            product.productId, product.quantity);
      }).toList();
      await Future.wait(updateStockFutures);

      // Fetch all orders to ensure we have the latest data
      final orders = await _repository.getAllOrders();
      emit(state.copyWith(allOrders: orders, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onUpdateOrder(UpdateOrderEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _repository.updateOrder(event.order);
      final orders = state.allOrders
          .map((o) => o.id == event.order.id ? event.order : o)
          .toList();
      emit(state.copyWith(allOrders: orders, status: DataStatus.success));
    } catch (e) {
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
}
