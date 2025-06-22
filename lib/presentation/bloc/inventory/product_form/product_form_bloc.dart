import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/constants/constants.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/models/unit.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/presentation/models/form_unit.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

part 'product_form_event.dart';
part 'product_form_state.dart';

class ProductFormBloc extends Bloc<ProductFormEvent, ProductFormState> {
  ProductFormBloc()
      : formKey = GlobalKey<FormState>(),
        super(const ProductFormState()) {
    on<NameFieldChangedEvent>(_onNameChanged);
    on<SkuFieldChangedEvent>(_onSkuChanged);
    on<CategoryFieldChangedEvent>(_onCategoryChanged);
    on<CategoryIdChangedEvent>(_onCategoryIdChanged);
    on<DescriptionChangedEvent>(_onDescriptionChanged);
    on<PriceFieldChangedEvent>(_onPriceChanged);
    on<CostFieldChangedEvent>(_onCostChanged);
    on<QuantityFieldChangedEvent>(_onQuantityChanged);
    on<MainUnitFieldChangedEvent>(_onMainUnitChanged);
    on<CriticalLevelFieldChangedEvent>(_onCriticalLevelChanged);
    on<MinReorderDelayFieldChangedEvent>(_onMinReorderDelayChanged);
    on<MaxReorderDelayFieldChangedEvent>(_onMaxReorderDelayChanged);
    on<DeadstockFieldChangedEvent>(_onDeadStockChanged);
    on<FastMovingStockFieldChangedEvent>(_onFastMovingStockChanged);
    on<SecondaryUnitFieldNameChangedEvent>(_onSecondaryUnitNameChanged);
    on<SecondaryUnitFieldFactorChangedEvent>(_onSecondaryUnitFactorChanged);
    on<SecondaryUnitFieldAddedEvent>(_onSecondaryUnitAdded);
    on<SecondaryUnitFieldDeletedEvent>(_onSecondaryUnitDeleted);
    on<ProductStatusChangedEvent>(_onProductStatusChanged);
    on<FormButtonPressedEvent>(_onButtonPressed);
    on<FormResetEvent>(_onFormReset);
    on<FormSubmittedEvent>(_onFormSubmitted);
    on<ProductLoadedEvent>(_onProductLoaded);
  }
  static ProductFormBloc fromProduct(Product product, List<Unit> units) {
    final bloc = ProductFormBloc();
    final secondaryUnits = units.where((unit) => unit.productId == product.id).toList();
    bloc.add(ProductLoadedEvent(
      product,
      secondaryUnits,
    ));

    return bloc;
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

  void _onDescriptionChanged(DescriptionChangedEvent event, Emitter<ProductFormState> emit) {
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
    final quantity = event.quantity;
    // Implementing requested feature for default critical level

    if (state.criticalLevel == 0) {
      emit(state.copyWith(isCriticalLevelEdited: false));
    }

    if (!state.isCriticalLevelEdited) {
      final criticalLevel = double.parse((quantity / 3.0).toStringAsFixed(2));
      emit(state.copyWith(quantity: quantity, criticalLevel: criticalLevel));
    } else {
      emit(state.copyWith(quantity: quantity));
    }
  }

  void _onMainUnitChanged(MainUnitFieldChangedEvent event, Emitter<ProductFormState> emit) {
    final mainUnit = event.unit;
    return emit(state.copyWith(mainUnit: mainUnit));
  }

  void _onSecondaryUnitNameChanged(
    SecondaryUnitFieldNameChangedEvent event,
    Emitter<ProductFormState> emit,
  ) {
    final name = event.name;
    final index = event.index;
    final alternativeUnits = List<FormUnit>.from(state.secondaryUnits);

    alternativeUnits[index] = alternativeUnits[index] //
        .copyWith(name: SecondaryUnitFormName(name));
    return emit(state.copyWith(secondaryUnits: alternativeUnits));
  }

  void _onSecondaryUnitFactorChanged(
    SecondaryUnitFieldFactorChangedEvent event,
    Emitter<ProductFormState> emit,
  ) {
    final SecondaryUnitFieldFactorChangedEvent(:mainQuantity, :unitQuantity, :index) = event;
    final alternativeUnits = List<FormUnit>.from(state.secondaryUnits);

    alternativeUnits[index] = alternativeUnits[index].copyWith(
      mainQuantity: SecondaryUnitFormMainQuantity(mainQuantity),
      unitQuantity: SecondaryUnitFormUnitQuantity(unitQuantity),
    );

    return emit(state.copyWith(secondaryUnits: alternativeUnits));
  }

  void _onMinReorderDelayChanged(
    MinReorderDelayFieldChangedEvent event,
    Emitter<ProductFormState> emit,
  ) {
    final minReorderDelay = event.minReorderDelay;
    emit(state.copyWith(minReorderDelay: minReorderDelay));
  }

  void _onMaxReorderDelayChanged(
    MaxReorderDelayFieldChangedEvent event,
    Emitter<ProductFormState> emit,
  ) {
    final maxReorderDelay = event.maxReorderDelay;
    printBoxed(maxReorderDelay);
    return emit(state.copyWith(maxReorderDelay: maxReorderDelay));
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

  void _onSecondaryUnitAdded(SecondaryUnitFieldAddedEvent event, Emitter<ProductFormState> emit) {
    final alternativeUnits = List<FormUnit>.from(state.secondaryUnits);
    alternativeUnits.add(const FormUnit.empty());
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

  void _onProductStatusChanged(ProductStatusChangedEvent event, Emitter<ProductFormState> emit) {
    final status = event.status;
    return emit(state.copyWith(archivedStatus: status));
  }

  Future<void> _onButtonPressed(
    FormButtonPressedEvent event,
    Emitter<ProductFormState> emit,
  ) async {
    emit(state.copyWith(formStatus: FormStatus.validating));
    await Future.delayed(Duration.zero);
    if (isClosed) return;

    try {
      if (formKey.currentState case final FormState formState when formState.validate()) {
        await Future.delayed(Duration.zero);

        if (kDebugMode) {
          printBoxed(event, 'ProductFormBloc: Button Pressed');
        }

        if (isClosed) return;

        emit(state.copyWith(
          formStatus: FormStatus.submitting,
          creatorId: event.creatorId,
          productId: event.productId,
          archivedStatus: state.archivedStatus ?? 0,
        ));
      } else {
        emit(state.copyWith(formStatus: FormStatus.invalid));
      }
    } catch (e) {
      if (kDebugMode) {
        printBoxed(e.toString().wrap, 'ProductFormBloc: Error on Button Pressed');
      }

      emit(state.copyWith(formStatus: FormStatus.error, errorMessage: e.toString()));
    }
  }

  void _onFormSubmitted(FormSubmittedEvent event, Emitter emit) {
    emit(state.copyWith(formStatus: FormStatus.submitted));
  }

  void _onFormReset(FormResetEvent event, Emitter emit) {
    emit(const ProductFormInitial());
  }

  void _onProductLoaded(ProductLoadedEvent event, Emitter emit) {
    emit(state.copyWith(formStatus: FormStatus.loading));
    try {
      emit(state.copyWith(
        productId: event.product.id,
        name: event.product.name,
        sku: event.product.sku,
        categoryName: event.product.categoryName ?? '',
        categoryId: event.product.categoryId,
        description: event.product.description,
        price: event.product.salePrice,
        cost: event.product.orderCost,
        quantity: event.product.quantity,
        mainUnit: event.product.mainUnit,
        secondaryUnits: event.secondaryUnits.isEmpty
            ? [const FormUnit.empty()]
            : event.secondaryUnits.map(FormUnit.fromUnit).toList(),
        criticalLevel: event.product.criticalLevel,
        deadStockThreshold: event.product.deadStockThreshold,
        fastMovingThreshold: event.product.fastMovingStockThreshold,
        archivedStatus: event.product.archiveStatus,
        formStatus: FormStatus.initial,
      ));
    } catch (e) {
      if (kDebugMode) {
        printBoxed(e.toString().wrap, 'ProductFormBloc: Error on Product Loaded');
      }
      emit(state.copyWith(formStatus: FormStatus.error, errorMessage: e.toString()));
    }
  }
}
