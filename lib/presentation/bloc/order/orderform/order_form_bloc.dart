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
    on<SaveOrderRequestEvent>(_onSaveOrderRequest);
  }

  final GlobalKey<FormState> formKey;

  void _onPayeeNameChanged(
      PayeeNameChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(
      payeeName: event.payeeName,
      payeeNameErrorMessage:
          event.payeeName.isEmpty ? 'Payee name is required.' : null,
    ));
  }

  void _onOrderDateChanged(
      OrderDateChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(
      orderDate: event.orderDate,
      orderDateErrorMessage: event.orderDate.isAfter(DateTime.now())
          ? 'Order date cannot be in the future.'
          : null,
      paymentDateErrorMessage: (state.paymentDate != null &&
              state.paymentDate!.isBefore(event.orderDate))
          ? 'Payment date cannot be before order date.'
          : null,
    ));
  }

  void _onPaymentDateChanged(
      PaymentDateChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(
      paymentDate: event.paymentDate,
      paymentDateErrorMessage: (event.paymentDate.isBefore(state.orderDate))
          ? 'Payment date cannot be before order date.'
          : null,
    ));
  }

  void _onExpenseTypeChanged(
      ExpenseTypeChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(expenseType: event.expenseType));
  }

  void _onPaymentMethodChanged(
      PaymentMethodChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(
      paymentMethod: event.paymentMethod,
      paymentMethodErrorMessage: event.paymentMethod == undefined
          ? 'Payment method is required.'
          : null,
    ));
  }

  void _onReferenceNumberChanged(
      ReferenceNumberChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(
      referenceNumber: event.referenceNumber,
      referenceNumberErrorMessage: event.referenceNumber.isEmpty
          ? 'Reference number is required.'
          : null,
    ));
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
      final adjustedRate =
          event.product.rate * (event.product.conversionFactor ?? 1);
      final adjustedProduct = event.product.copyWith(
        rate: adjustedRate,
        amount: adjustedRate * event.product.quantity,
      );
      updatedProducts[event.index] = adjustedProduct;
      final amountDue = updatedProducts.fold<double>(
        0,
        (previousValue, element) => previousValue + (element.amount),
      );
      emit(state.copyWith(products: updatedProducts, amountDue: amountDue));
    }
  }

  Future<void> _onFormButtonPressed(
      FormButtonPressedEvent event, Emitter<OrderFormState> emit) async {
    /// Validate required fields
    final payeeNameError =
        state.payeeName.isEmpty ? 'Payee name is required.' : null;
    final paymentMethodError =
        state.paymentMethod == undefined ? 'Payment method is required.' : null;
    final referenceNumberError =
        state.referenceNumber.isEmpty ? 'Reference number is required.' : null;

    // Check if products are valid
    final products = state.products;
    if (products.every(
      (product) =>
          product.productId == null &&
          product.description == null &&
          product.quantity <= 0 &&
          product.rate <= 0,
    )) {
      // Mark all products as having errors
      emit(state.copyWith(
        products: products
            .map((product) =>
                product.copyWith(errorMessage: 'Order items cannot be empty'))
            .toList(),
        status: FormStatus.error,
      ));
      return;
    }

    // Tag incomplete products
    final taggedProducts = products.map(
      (product) {
        if (product.productId == null &&
            (product.quantity > 0 ||
                product.description != null ||
                product.rate > 0)) {
          return product.copyWith(errorMessage: 'Item cannot be blank');
        }
        return product;
      },
    ).toList();

    if (taggedProducts.any((product) => product.errorMessage != null)) {
      emit(state.copyWith(
        products: taggedProducts,
        status: FormStatus.error,
      ));
      return;
    }

    // Emit state with all validation errors
    emit(state.copyWith(
      payeeNameErrorMessage: payeeNameError,
      paymentMethodErrorMessage: paymentMethodError,
      referenceNumberErrorMessage: referenceNumberError,
      products: taggedProducts,
    ));

    // Check if form is valid (including the form key validation)
    final bool isValid = (formKey.currentState?.validate() ?? false) &&
        payeeNameError == null &&
        paymentMethodError == null &&
        referenceNumberError == null &&
        !taggedProducts.any((product) => product.errorMessage != null);

    if (isValid) {
      emit(state.copyWith(status: FormStatus.submitting));
    } else {
      emit(state.copyWith(status: FormStatus.error));
    }
  }

  Future<void> _onFormSubmitted(
      FormSubmittedEvent event, Emitter<OrderFormState> emit) async {
    emit(state.copyWith(status: FormStatus.success));
  }

  void _onClearProducts(
      ClearProductsEvent event, Emitter<OrderFormState> emit) {
    final cleared = <FormProduct>[EmptyFormProduct()];
    emit(state.copyWith(products: cleared));
  }

  Future<void> _onSaveOrderRequest(
    SaveOrderRequestEvent event,
    Emitter<OrderFormState> emit,
  ) async {
    await Future.delayed(Duration.zero);

    /// Checks
    /// - Products must not be empty
    final products = state.products;
    final orderDateErrorMessage = state.orderDateErrorMessage;
    final paymentDateErrorMessage = state.paymentDateErrorMessage;
    final payeeNameErrorMessage = state.payeeNameErrorMessage;
    final paymentMethodErrorMessage = state.paymentMethodErrorMessage;
    final referenceNumberErrorMessage = state.referenceNumberErrorMessage;

    // Start validation
    emit(state.copyWith(status: FormStatus.validating));

    // Check if products are empty
    if (products.every(
      (product) =>
          product.productId == null &&
          product.description == null &&
          product.quantity <= 0 &&
          product.rate <= 0,
    )) {
      emit(
        state.copyWith(
          status: FormStatus.error,
          products: products
              .map(
                (product) => product.copyWith(
                  errorMessage: 'Order items cannot be empty',
                ),
              )
              .toList(),
          dialogErrorMessage: 'Please add at least one product.',
        ),
      );
      return;
    }

    // Tag incomplete products
    final taggedProducts = products.map(
      (product) {
        if (product.productId == null &&
            (product.quantity > 0 ||
                product.description != null ||
                product.rate > 0)) {
          return product.copyWith(errorMessage: 'Item cannot be blank');
        }
        return product;
      },
    ).toList();

    if (taggedProducts
        .any((product) => product.errorMessage == 'Item cannot be blank')) {
      return emit(
        state.copyWith(
          status: FormStatus.error,
          products: taggedProducts,
          dialogErrorMessage: 'Please fill in all product details.',
        ),
      );
    }

    // Check required fields
    if (payeeNameErrorMessage != null ||
        paymentMethodErrorMessage != null ||
        referenceNumberErrorMessage != null) {
      return emit(
        state.copyWith(
          status: FormStatus.error,
          dialogErrorMessage: payeeNameErrorMessage ??
              paymentMethodErrorMessage ??
              referenceNumberErrorMessage ??
              'Please check required fields.',
        ),
      );
    }

    // Check dates
    if (orderDateErrorMessage != null || paymentDateErrorMessage != null) {
      return emit(
        state.copyWith(
          status: FormStatus.error,
          dialogErrorMessage: 'Please select valid order and payment dates.',
        ),
      );
    }

    // If all validation passes, proceed with submission
    emit(state.copyWith(
      dialogErrorMessage: null,
      creationDate: event.creationDate,
      creatorId: event.creatorId,
      id: event.id,
      status: FormStatus.submitting,
    ));
  }
}
