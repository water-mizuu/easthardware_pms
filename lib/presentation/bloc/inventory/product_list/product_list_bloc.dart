import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/repository/product_repository.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'product_list_event.dart';
part 'product_list_state.dart';

class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  ProductListBloc(this._repository, ProductListState initialState)
      : super(initialState) {
    on<LoadAllProductsEvent>(_onLoad);
    on<ReloadAllProductsEvent>(_onReloadAllProducts);
    on<AddProductEvent>(_onAdd);
    on<UpdateProductEvent>(_onUpdate);
    on<DeleteProductEvent>(_onDelete);
  }
  final ProductRepository _repository;

  Future<void> _onLoad(LoadAllProductsEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      emit(
        state.copyWith(
          allProducts: await _repository.getAllProducts(),
          lowStockProducts: await _repository.getLowStockProducts(),
          fastMovingProducts: await _repository.getFastMovingProducts(),
          deadStockProducts: await _repository.getDeadStockProducts(),
          status: DataStatus.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onReloadAllProducts(
      ReloadAllProductsEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      emit(
        state.copyWith(
          allProducts: await _repository.getAllProducts(),
          lowStockProducts: await _repository.getLowStockProducts(),
          fastMovingProducts: await _repository.getFastMovingProducts(),
          deadStockProducts: await _repository.getDeadStockProducts(),
          status: DataStatus.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAdd(AddProductEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final insertedProduct = event.product.copyWith(
        isBelowCriticalLevel:
            event.product.quantity <= event.product.criticalLevel,
        isDeadStock: false,
        isFastMovingStock: false,
      );

      await _repository.insertProduct(event.product);

      final products = List<Product>.from(state.allProducts)
        ..add(insertedProduct);
      final lowStockProducts = List<Product>.from(state.lowStockProducts);

      if (event.product.quantity <= event.product.criticalLevel) {
        lowStockProducts.add(event.product);
      }
      emit(
        state.copyWith(
          allProducts: products,
          lowStockProducts: lowStockProducts,
          status: DataStatus.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onUpdate(UpdateProductEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));

    try {
      final updatedProduct = event.product.copyWith(
        isBelowCriticalLevel:
            event.product.quantity <= event.product.criticalLevel,
      );
      await _repository.updateProduct(updatedProduct);

      final updatedProducts = List<Product>.from(state.allProducts);
      final index =
          updatedProducts.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        updatedProducts[index] = updatedProduct;
      }

      final updatedLowStock =
          updatedProducts.where((p) => p.isBelowCriticalLevel == true).toList();

      emit(
        state.copyWith(
          allProducts: updatedProducts,
          lowStockProducts: updatedLowStock,
          status: DataStatus.success,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error updating product: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onDelete(DeleteProductEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _repository.deleteProduct(event.productId);
      emit(
        state.copyWith(
          allProducts: await _repository.getAllProducts(),
          lowStockProducts: await _repository.getLowStockProducts(),
          fastMovingProducts: await _repository.getFastMovingProducts(),
          deadStockProducts: await _repository.getDeadStockProducts(),
          status: DataStatus.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }
}
