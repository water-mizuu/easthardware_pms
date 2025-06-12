import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/models/form_product.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'order_form_event.dart';
part 'order_form_state.dart';

class OrderFormBloc extends Bloc<OrderFormEvent, OrderFormState> {
  OrderFormBloc({int? expenseType})
      : formKey = GlobalKey<FormState>(),
        super(expenseType != null
            ? OrderFormState(expenseType: expenseType)
            : OrderFormState()) {
    on<PayeeNameChangedEvent>(_onPayeeNameChanged);
    on<OrderDateChangedEvent>(_onOrderDateChanged);
    on<ExpenseTypeChangedEvent>(_onExpenseTypeChanged);
    on<PaymentMethodChangedEvent>(_onPaymentMethodChanged);
    on<ReferenceNumberChangedEvent>(_onReferenceNumberChanged);
    on<PaymentDateChangedEvent>(_onPaymentDateChanged);
    on<MemoChangedEvent>(_onMemoChanged);
    on<ProductAddedEvent>(_onProductAdded);
    on<ProductRemovedEvent>(_onProductRemoved);
    on<ProductSelectedEvent>(_onProductSelected);
    on<ProductUpdatedEvent>(_onProductUpdated);
    on<FormButtonPressedEvent>(_onFormButtonPressed);
    on<FormSubmittedEvent>(_onFormSubmitted);
    on<ClearProductsEvent>(_onClearProducts);
  }

  final GlobalKey<FormState> formKey;

  void _onPayeeNameChanged(
      PayeeNameChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(payeeName: event.payeeName));
  }

  void _onOrderDateChanged(
      OrderDateChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(orderDate: event.orderDate));
  }

  void _onExpenseTypeChanged(
      ExpenseTypeChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(expenseType: event.expenseType));
  }

  void _onPaymentMethodChanged(
      PaymentMethodChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(paymentMethod: event.paymentMethod));
  }

  void _onReferenceNumberChanged(
      ReferenceNumberChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(referenceNumber: event.referenceNumber));
  }

  void _onPaymentDateChanged(
      PaymentDateChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(paymentDate: event.paymentDate));
  }

  void _onMemoChanged(MemoChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(memo: event.memo));
  }

  void _onProductAdded(ProductAddedEvent event, Emitter<OrderFormState> emit) {
    final updatedProducts = List<FormProduct>.from(state.products)
      ..add(EmptyFormProduct());
    emit(state.copyWith(products: updatedProducts));
  }

  void _onProductRemoved(
      ProductRemovedEvent event, Emitter<OrderFormState> emit) {
    final updatedProducts = List<FormProduct>.from(state.products)
      ..removeAt(event.index);
    emit(state.copyWith(products: updatedProducts));
  }

  void _onProductSelected(
      ProductSelectedEvent event, Emitter<OrderFormState> emit) {
    final updatedProducts = List<FormProduct>.from(state.products);
    if (event.index != -1) {
      updatedProducts[event.index] = FormProduct.fromProduct(event.product)
          .copyWith(rate: event.product.orderCost, amount: 0);
      emit(state.copyWith(products: updatedProducts));
    }
  }

  void _onProductUpdated(
      ProductUpdatedEvent event, Emitter<OrderFormState> emit) {
    final updatedProducts = List<FormProduct>.from(state.products);
    if (event.index != -1) {
      updatedProducts[event.index] = event.product;
      emit(state.copyWith(products: updatedProducts));
    }
  }

  Future<void> _onFormButtonPressed(
      FormButtonPressedEvent event, Emitter<OrderFormState> emit) async {
    if (formKey.currentState?.validate() ?? false) {
      emit(state.copyWith(status: FormStatus.submitting));
    } else {
      emit(state.copyWith(status: FormStatus.invalid));
    }
  }

  Future<void> _onFormSubmitted(
      FormSubmittedEvent event, Emitter<OrderFormState> emit) async {
    emit(state.copyWith(status: FormStatus.success));
  }

  void _onClearProducts(
      ClearProductsEvent event, Emitter<OrderFormState> emit) {
    if (state.products.isEmpty) return;
    final cleared = <FormProduct>[EmptyFormProduct()];
    emit(state.copyWith(products: cleared));
  }
}
