import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/constants/constants.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/presentation/models/form_unit.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

part 'product_form_event.dart';
part 'product_form_state.dart';

class ProductFormBloc extends Bloc<ProductFormEvent, ProductFormState> {
  final GlobalKey<FormState> formKey;
  ProductFormBloc({
    Product? product,
    List<Unit>? units,
  })  : formKey = GlobalKey<FormState>(),
        super(
          product == null || units == null
              ? ProductFormState()
              : ProductFormState.fromProduct(product, units),
        ) {
    on<NameFieldChangedEvent>(_onNameChanged);
    on<SkuFieldChangedEvent>(_onSkuChanged);
    on<CategoryFieldChangedEvent>(_onCategoryChanged);
    on<CategoryIdChangedEvent>(_onCategoryIdChanged);
    on<DescriptionFieldChangedEvent>(_onDescriptionChanged);
    on<PriceFieldChangedEvent>(_onPriceChanged);
    on<CostFieldChangedEvent>(_onCostChanged);
    on<QuantityFieldChangedEvent>(_onQuantityChanged);
    on<MainUnitFieldChangedEvent>(_onMainUnitChanged);
    on<SecondaryUnitFieldNameChangedEvent>(_onSecondaryUnitNameChanged);
    on<SecondaryUnitFieldFactorChangedEvent>(_onSecondaryUnitFactorChanged);
    on<SecondaryUnitFieldAddedEvent>(_onSecondaryUnitAdded);
    on<SecondaryUnitFieldDeletedEvent>(_onSecondaryUnitDeleted);
    on<CriticalLevelFieldChangedEvent>(_onCriticalLevelChanged);
    on<DeadstockFieldChangedEvent>(_onDeadStockChanged);
    on<FastMovingStockFieldChangedEvent>(_onFastMovingStockChanged);
    on<ProductStatusChangedEvent>(_onProductStatusChanged);
    on<FormButtonPressedEvent>(_onButtonPressed);
    on<FormResetEvent>(_onFormReset);
    on<FormSubmittedEvent>(_onFormSubmitted);
    on<ProductLoadedEvent>(_onProductLoaded);
  }

  void _onNameChanged(NameFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final String name = event.name;
    return emit(state.copyWith(name: name));
  }

  void _onSkuChanged(SkuFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final String sku = event.sku;
    return emit(state.copyWith(sku: sku));
  }

  void _onCategoryChanged(CategoryFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final String category = event.category;
    return emit(state.copyWith(categoryName: category));
  }

  void _onCategoryIdChanged(CategoryIdChangedEvent event, Emitter<ProductFormState> emit) {
    final int categoryId = event.categoryId;
    return emit(state.copyWith(categoryId: categoryId));
  }

  void _onDescriptionChanged(DescriptionFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final String description = event.description;
    return emit(state.copyWith(description: description));
  }

  void _onPriceChanged(PriceFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final String price = event.price;
    return emit(state.copyWith(price: price));
  }

  void _onCostChanged(CostFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final String cost = event.cost;
    return emit(state.copyWith(cost: cost));
  }

  void _onQuantityChanged(QuantityFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final String quantity = event.quantity;
    // Implementing requested feature for default critical level
    // Is quantity is numeric
    // If true, and criticalLevel is not empty, calculate default critical level
    // If false, do nothing
    if (quantity.isNotEmpty && double.tryParse(quantity) == null) {
      emit(state.copyWith(quantity: quantity));
      return;
    }
    if (state.criticalLevel.isEmpty) {
      emit(state.copyWith(isCriticalLevelEdited: false));
    }

    if (!state.isCriticalLevelEdited) {
      // If critical level is not edited, calculate default critical level
      // If critical level is empty, calculate default critical level
      final double quantityValue = double.parse(quantity);
      final double criticalLevel = quantityValue * 0.3;
      emit(state.copyWith(quantity: quantity, criticalLevel: criticalLevel.toString()));
    } else {
      emit(state.copyWith(quantity: quantity));
    }
  }

  void _onMainUnitChanged(MainUnitFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final String mainUnit = event.unit;
    return emit(state.copyWith(mainUnit: mainUnit));
  }

  void _onSecondaryUnitNameChanged(
      SecondaryUnitFieldNameChangedEvent event, Emitter<ProductFormState> emit) {
    final String name = event.name;
    final int index = event.index;
    final List<FormUnit> alternativeUnits = List.from(state.secondaryUnits);

    alternativeUnits[index] = alternativeUnits[index].copyWith(name: name);
    return emit(state.copyWith(secondaryUnits: alternativeUnits));
  }

  void _onSecondaryUnitFactorChanged(
      SecondaryUnitFieldFactorChangedEvent event, Emitter<ProductFormState> emit) {
    final String factor = event.factor;
    final int index = event.index;
    final List<FormUnit> alternativeUnits = List.from(state.secondaryUnits);

    alternativeUnits[index] = alternativeUnits[index].copyWith(factor: factor);
    return emit(state.copyWith(secondaryUnits: alternativeUnits));
  }

  void _onSecondaryUnitAdded(SecondaryUnitFieldAddedEvent event, Emitter<ProductFormState> emit) {
    final List<FormUnit> alternativeUnits = List.from(state.secondaryUnits);
    alternativeUnits.add(FormUnit(name: '', factor: ''));
    emit(state.copyWith(secondaryUnits: alternativeUnits));
  }

  void _onSecondaryUnitDeleted(
      SecondaryUnitFieldDeletedEvent event, Emitter<ProductFormState> emit) {
    final updated = [...state.secondaryUnits];
    if (updated.length > 1) {
      updated.removeAt(event.index);
      emit(state.copyWith(secondaryUnits: updated));
    }
  }

  void _onCriticalLevelChanged(
      CriticalLevelFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final String criticalLevel = event.criticalLevel;
    return emit(state.copyWith(criticalLevel: criticalLevel, isCriticalLevelEdited: true));
  }

  void _onDeadStockChanged(DeadstockFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final String threshold = event.threshold;
    return emit(state.copyWith(deadStockThreshold: threshold));
  }

  void _onFastMovingStockChanged(
      FastMovingStockFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final String threshold = event.threshold;
    return emit(state.copyWith(fastMovingThreshold: threshold));
  }

  void _onProductStatusChanged(ProductStatusChangedEvent event, Emitter<ProductFormState> emit) {
    final int status = event.status;
    return emit(state.copyWith(archiveStatus: status));
  }

  void _onButtonPressed(FormButtonPressedEvent event, Emitter<ProductFormState> emit) async {
    emit(state.copyWith(formStatus: FormStatus.validating));
    await Future.delayed(Duration.zero);
    try {
      if (formKey.currentState case FormState formState when formState.validate()) {
        emit(state.copyWith(formStatus: FormStatus.valid));
        Future.delayed(Duration.zero);
        emit(state.copyWith(
          formStatus: FormStatus.submitting,
          creatorId: event.creatorId,
          productId: event.productId,
          archiveStatus: state.archiveStatus ?? 0,
        ));
      } else {
        emit(state.copyWith(formStatus: FormStatus.invalid));
      }
    } catch (e) {
      emit(state.copyWith(formStatus: FormStatus.error));
    }
  }

  void _onFormSubmitted(FormSubmittedEvent event, Emitter emit) {
    emit(state.copyWith(formStatus: FormStatus.submitted));
  }

  void _onFormReset(FormResetEvent event, Emitter emit) {
    emit(ProductFormInitial());
  }

  void _onProductLoaded(ProductLoadedEvent event, Emitter emit) {
    try {
      emit(state.copyWith(
        name: event.product.name,
        sku: event.product.sku,
        categoryName: event.product.categoryName ?? '',
        categoryId: event.product.categoryId,
        description: event.product.description,
        price: event.product.salePrice.toString(),
        cost: event.product.orderCost.toString(),
        quantity: event.product.quantity.toString(),
        mainUnit: event.product.mainUnit,
        secondaryUnits: event.secondaryUnits.map(FormUnit.fromUnit).toList(),
        criticalLevel: event.product.criticalLevel.toString(),
        deadStockThreshold: event.product.deadStockThreshold.toString(),
        fastMovingThreshold: event.product.fastMovingStockThreshold.toString(),
        archiveStatus: event.product.archiveStatus,
        formStatus: FormStatus.initial,
      ));
    } catch (e) {
      emit(state.copyWith(formStatus: FormStatus.error));
    }
  }
}
