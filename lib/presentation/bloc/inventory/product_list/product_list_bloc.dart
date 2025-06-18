import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/domain/repository/category_repository.dart';
import 'package:easthardware_pms/domain/repository/product_repository.dart';
import 'package:easthardware_pms/domain/repository/unit_repository.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

part 'product_list_event.dart';
part 'product_list_state.dart';

class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  ProductListBloc(
    this._productRepository,
    this._categoryRepository,
    this._unitRepository,
    ProductListState initialState,
  ) : super(initialState) {
    on<LoadAllProductsEvent>(_onLoad);
    on<ReloadAllProductsEvent>(_onReloadAllProducts);
    on<AddProductEvent>(_onAdd);
    on<UpdateProductEvent>(_onUpdate);
    on<DeleteProductEvent>(_onDelete);
  }
  final ProductRepository _productRepository;
  final UnitRepository _unitRepository;
  final CategoryRepository _categoryRepository;

  Future<void> _onLoad(LoadAllProductsEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final categories = await _categoryRepository.getAllCategories();
      final allProducts = (await _productRepository.getAllProducts()).map((product) {
        final category = categories.firstWhere(
          (cat) => cat.id == product.categoryId,
          orElse: () => Category(id: product.categoryId, name: 'Uncategorized'),
        );
        return product.copyWith(categoryName: category.name);
      }).toList();
      final lowStockProducts = (await _productRepository.getLowStockProducts()).map((product) {
        final category = categories.firstWhere(
          (cat) => cat.id == product.categoryId,
          orElse: () => Category(id: product.categoryId, name: 'Uncategorized'),
        );
        return product.copyWith(categoryName: category.name);
      }).toList();
      final fastMovingProducts = (await _productRepository.getFastMovingProducts()).map((product) {
        final category = categories.firstWhere(
          (cat) => cat.id == product.categoryId,
          orElse: () => Category(id: product.categoryId, name: 'Uncategorized'),
        );
        return product.copyWith(categoryName: category.name);
      }).toList();
      final deadStockProducts = (await _productRepository.getDeadStockProducts()).map((product) {
        final category = categories.firstWhere(
          (cat) => cat.id == product.categoryId,
          orElse: () => Category(id: product.categoryId, name: 'Uncategorized'),
        );
        return product.copyWith(categoryName: category.name);
      }).toList();

      emit(
        state.copyWith(
          allProducts: allProducts,
          lowStockProducts: lowStockProducts,
          fastMovingProducts: fastMovingProducts,
          deadStockProducts: deadStockProducts,
          status: DataStatus.success,
        ),
      );
    } catch (e, stackTrace) {
      printBoxed('Error loading products: $e\n$stackTrace', 'ProductListBloc');
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onReloadAllProducts(ReloadAllProductsEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final categories = await _categoryRepository.getAllCategories();
      final allProducts = (await _productRepository.getAllProducts()).map((product) {
        final category = categories.firstWhere(
          (cat) => cat.id == product.categoryId,
          orElse: () => Category(id: product.categoryId, name: 'Uncategorized'),
        );
        return product.copyWith(categoryName: category.name);
      }).toList();
      final lowStockProducts = (await _productRepository.getLowStockProducts()).map((product) {
        final category = categories.firstWhere(
          (cat) => cat.id == product.categoryId,
          orElse: () => Category(id: product.categoryId, name: 'Uncategorized'),
        );
        return product.copyWith(categoryName: category.name);
      }).toList();
      final fastMovingProducts = (await _productRepository.getFastMovingProducts()).map((product) {
        final category = categories.firstWhere(
          (cat) => cat.id == product.categoryId,
          orElse: () => Category(id: product.categoryId, name: 'Uncategorized'),
        );
        return product.copyWith(categoryName: category.name);
      }).toList();
      final deadStockProducts = (await _productRepository.getDeadStockProducts()).map((product) {
        final category = categories.firstWhere(
          (cat) => cat.id == product.categoryId,
          orElse: () => Category(id: product.categoryId, name: 'Uncategorized'),
        );
        return product.copyWith(categoryName: category.name);
      }).toList();

      emit(
        state.copyWith(
          allProducts: allProducts,
          lowStockProducts: lowStockProducts,
          fastMovingProducts: fastMovingProducts,
          deadStockProducts: deadStockProducts,
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
      // 1. Insert Category if not exist
      final insertedCategory = ( //
              await _categoryRepository.getCategoryByName(event.category.name)) ??
          await _categoryRepository.insertCategory(event.category);

      // 2. Insert Product
      final insertedProduct = ( //
          await _productRepository.insertProduct(
        event.product.copyWith(
          categoryId: insertedCategory.id,
          categoryName: insertedCategory.name,
        ),
      ));

      final clearedProduct = insertedProduct.copyWith(
        isBelowCriticalLevel: event.product.quantity <= event.product.criticalLevel,
        isDeadStock: false,
        isFastMovingStock: false,
      );

      // 3. Insert Units on returned Product Id
      final units = event.units
          .where((unit) => unit.name.isNotEmpty)
          .map((unit) => unit.copyWith(productId: clearedProduct.id)) //
          .toList();
      for (final unit in units) {
        await _unitRepository.insertUnit(unit);
      }

      final products = [...state.allProducts, clearedProduct];
      final lowStockProducts = List<Product>.from(state.lowStockProducts);

      if (event.product.quantity <= event.product.criticalLevel) {
        lowStockProducts.add(event.product);
      }

      emit(
        state.copyWith(
          allProducts: products,
          latest: clearedProduct,
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
      // 1. Update Category if not exist
      final existingCategory = await _categoryRepository.getCategoryByName(event.category.name);
      final category = existingCategory ?? await _categoryRepository.insertCategory(event.category);

      // 2. Update Product
      final updatedProduct = await _productRepository.updateProduct(
        event.product.copyWith(categoryId: category.id, categoryName: category.name),
      );
      final clearedProduct = updatedProduct.copyWith(
        isBelowCriticalLevel: event.product.quantity <= event.product.criticalLevel,
      );

      // 3. Update Units
      final existingUnits = await _unitRepository.getAllUnitsOfProductId(clearedProduct.id!);
      final unitsToUpdate = event.units
          .where((unit) => unit.name.isNotEmpty)
          .map((unit) => unit.copyWith(productId: clearedProduct.id))
          .toList();

      // Delete units that are not in the new list
      for (final existingUnit in existingUnits) {
        if (!unitsToUpdate.any((unit) => unit.id == existingUnit.id)) {
          await _unitRepository.deleteUnit(existingUnit.id!);
        }
      }

      // Insert or update units
      for (final unit in unitsToUpdate) {
        if (unit.id != null && existingUnits.any((existingUnit) => existingUnit.id == unit.id)) {
          await _unitRepository.updateUnit(unit);
        } else {
          await _unitRepository.insertUnit(unit);
        }
      }
      // 4. Update state
      final updatedProducts = List<Product>.from(state.allProducts);
      final index = updatedProducts.indexWhere((p) => p.id == clearedProduct.id);
      if (index != -1) {
        updatedProducts[index] = clearedProduct;
      }

      final lowstock = await _productRepository.getLowStockProducts();
      final fastmoving = await _productRepository.getFastMovingProducts();
      final deadstock = await _productRepository.getDeadStockProducts();

      emit(
        state.copyWith(
          allProducts: updatedProducts,
          lowStockProducts: lowstock,
          fastMovingProducts: fastmoving,
          deadStockProducts: deadstock,
          latest: clearedProduct,
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
      await _productRepository.deleteProduct(event.productId);
      emit(
        state.copyWith(
          allProducts: await _productRepository.getAllProducts(),
          lowStockProducts: await _productRepository.getLowStockProducts(),
          fastMovingProducts: await _productRepository.getFastMovingProducts(),
          deadStockProducts: await _productRepository.getDeadStockProducts(),
          status: DataStatus.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }
}
