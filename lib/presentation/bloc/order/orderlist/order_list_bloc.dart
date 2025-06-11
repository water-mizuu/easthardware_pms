import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/repository/order_repository.dart';
import 'package:equatable/equatable.dart';

part 'order_list_event.dart';
part 'order_list_state.dart';

class OrderListBloc extends Bloc<OrderListEvent, OrderListState> {
  OrderListBloc(this._repository, OrderListState initialState) : super(initialState) {
    on<FetchAllOrdersEvent>(_onFetchOrders);
    on<AddOrderEvent>(_onAddOrder);
    on<UpdateOrderEvent>(_onUpdateOrder);
    on<DeleteOrderEvent>(_onDeleteOrder);
    on<ChangeRowsPerPageEvent>(_onChangeRowsPerPage);
  }
  final OrderRepository _repository;

  Future<void> _onFetchOrders(FetchAllOrdersEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final orders = await _repository.getAllOrders();
      emit(state.copyWith(allOrders: orders, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAddOrder(AddOrderEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final order = await _repository.insertOrder(event.order);
      final orders = List<Order>.from(state.allOrders)..add(order);
      emit(state.copyWith(allOrders: orders, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onChangeRowsPerPage(ChangeRowsPerPageEvent event, Emitter emit) async {
    emit(state.copyWith(rowsPerPage: event.rowsPerPage));
  }

  Future<void> _onUpdateOrder(UpdateOrderEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _repository.updateOrder(event.order);
      final orders = state.allOrders.map((o) => o.id == event.order.id ? event.order : o).toList();
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
