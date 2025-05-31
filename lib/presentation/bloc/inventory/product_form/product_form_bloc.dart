import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/constants/constants.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/presentation/models/form_unit.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

part 'product_form_event.dart';
part 'product_form_state.dart';

class ProductFormBloc extends Bloc<ProductFormEvent, ProductFormState> {
  ProductFormBloc({
    Product? product,
    List<Unit>? units,
  })  : assert(
          (product == null) == (units == null),
          "Either none of them should be provided, or both of them.",
        ),
        formKey = GlobalKey<FormState>(),
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
  final GlobalKey<FormState> formKey;

  @override
  void onEvent(ProductFormEvent event) {
    if (kDebugMode) {
      printBoxed(event, 'ProductFormBloc');
    }
    super.onEvent(event);
  }

  void _onNameChanged(NameFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final name = event.name;
    return emit(state.copyWith(name: name));
  }

  void _onSkuChanged(SkuFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final sku = event.sku;
    return emit(state.copyWith(sku: sku));
  }

  void _onCategoryChanged(CategoryFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final category = event.category;
    return emit(state.copyWith(categoryName: category));
  }

  void _onCategoryIdChanged(CategoryIdChangedEvent event, Emitter<ProductFormState> emit) {
    final categoryId = event.categoryId;
    return emit(state.copyWith(categoryId: categoryId));
  }

  void _onDescriptionChanged(DescriptionFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final description = event.description;
    return emit(state.copyWith(description: description));
  }

  void _onPriceChanged(PriceFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final price = event.price;
    return emit(state.copyWith(price: price));
  }

  void _onCostChanged(CostFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final cost = event.cost;
    return emit(state.copyWith(cost: cost));
  }

  void _onQuantityChanged(QuantityFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final quantity = event.quantity.trim();
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

      final quantityValue = double.parse(quantity);
      final criticalLevel = quantityValue * 0.3;
      emit(state.copyWith(quantity: quantity, criticalLevel: criticalLevel.toString()));
    } else {
      emit(state.copyWith(quantity: quantity));
    }
  }

  void _onMainUnitChanged(MainUnitFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final mainUnit = event.unit;
    return emit(state.copyWith(mainUnit: mainUnit));
  }

  void _onSecondaryUnitNameChanged(
      SecondaryUnitFieldNameChangedEvent event, Emitter<ProductFormState> emit) {
    final name = event.name;
    final index = event.index;
    final alternativeUnits = List<FormUnit>.from(state.secondaryUnits);

    alternativeUnits[index] = alternativeUnits[index].copyWith(name: name);
    return emit(state.copyWith(secondaryUnits: alternativeUnits));
  }

  void _onSecondaryUnitFactorChanged(
    SecondaryUnitFieldFactorChangedEvent event,
    Emitter<ProductFormState> emit,
  ) {
    final SecondaryUnitFieldFactorChangedEvent(:mainQuantity, :unitQuantity, :index) = event;
    final alternativeUnits = List<FormUnit>.from(state.secondaryUnits);

    alternativeUnits[index] = alternativeUnits[index].copyWith(
      mainQuantity: mainQuantity,
      unitQuantity: unitQuantity,
    );

    return emit(state.copyWith(secondaryUnits: alternativeUnits));
  }

  void _onSecondaryUnitAdded(SecondaryUnitFieldAddedEvent event, Emitter<ProductFormState> emit) {
    final alternativeUnits = List<FormUnit>.from(state.secondaryUnits);
    alternativeUnits.add(FormUnit(name: '', mainQuantity: '', unitQuantity: ''));
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
    final criticalLevel = event.criticalLevel;
    return emit(state.copyWith(criticalLevel: criticalLevel, isCriticalLevelEdited: true));
  }

  void _onDeadStockChanged(DeadstockFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final threshold = event.threshold;
    return emit(state.copyWith(deadStockThreshold: threshold));
  }

  void _onFastMovingStockChanged(
      FastMovingStockFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final threshold = event.threshold;
    return emit(state.copyWith(fastMovingThreshold: threshold));
  }

  void _onProductStatusChanged(ProductStatusChangedEvent event, Emitter<ProductFormState> emit) {
    final status = event.status;
    return emit(state.copyWith(archiveStatus: status));
  }

  Future<void> _onButtonPressed(
    FormButtonPressedEvent event,
    Emitter<ProductFormState> emit,
  ) async {
    emit(state.copyWith(formStatus: FormStatus.validating));
    await Future.delayed(Duration.zero);
    try {
      if (formKey.currentState case final FormState formState when formState.validate()) {
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
