import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart' show FormStatus, OrderType;
import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/services/cryptography_service.dart';
import 'package:easthardware_pms/presentation/models/form_order_item.dart';
import 'package:easthardware_pms/presentation/models/form_product.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'order_form_event.dart';
part 'order_form_state.dart';

class OrderFormBloc extends Bloc<OrderFormEvent, OrderFormState> {
  OrderFormBloc(super.state) : formKey = GlobalKey<FormState>() {
    on<PayeeNameChangedEvent>(_onPayeeNameChanged);
    on<OrderDateChangedEvent>(_onOrderDateChanged);
    on<ExpenseTypeChangedEvent>(_onExpenseTypeChanged);
    on<PaymentMethodChangedEvent>(_onPaymentMethodChanged);
    on<ReferenceNumberChangedEvent>(_onReferenceNumberChanged);
    on<MemoChangedEvent>(_onMemoChanged);
    on<ProductAddedEvent>(_onProductAdded);
    on<ProductRemovedEvent>(_onProductRemoved);
    on<ProductSelectedEvent>(_onProductSelected);
    on<ProductUpdatedEvent>(_onProductUpdated);
    on<OrderItemAddedEvent>(_onOrderItemAdded);
    on<OrderItemRemovedEvent>(_onOrderItemRemoved);
    on<OrderItemUpdatedEvent>(_onOrderItemUpdated);
    on<ClearOrderItemsEvent>(_onClearOrderItems);
    on<FormSubmittedEvent>(_onFormSubmitted);
    on<ClearProductsEvent>(_onClearProducts);
    on<SaveRestockOrderRequestEvent>(_onSaveRestockOrderRequest);
    on<SaveExpenseOrderRequestEvent>(_onSaveExpenseOrderRequest);
  }

  factory OrderFormBloc.RestockOrder() {
    return OrderFormBloc(
      OrderFormState.RestockOrder(null, null),
    );
  }
  factory OrderFormBloc.ExpenseOrder() {
    return OrderFormBloc(
      OrderFormState.ExpenseOrder(null),
    );
  }
  factory OrderFormBloc.FromRestockOrder(Product? product, int? orderId) {
    // TODO: Implement
    return OrderFormBloc(
      OrderFormState.RestockOrder(product, orderId),
    );
  }
  factory OrderFormBloc.FromExpenseOrder(int? orderId) {
    // TODO: Implement
    return OrderFormBloc(
      OrderFormState.ExpenseOrder(orderId),
    );
  }

  final GlobalKey<FormState> formKey;

  void _onPayeeNameChanged(PayeeNameChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(
      payeeName: event.payeeName,
      payeeNameErrorMessage: event.payeeName.isEmpty ? 'Payee name is required.' : null,
    ));
  }

  void _onOrderDateChanged(OrderDateChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(
      orderDate: event.orderDate,
      orderDateErrorMessage:
          event.orderDate.isAfter(DateTime.now()) ? 'Order date cannot be in the future.' : null,
    ));
  }

  void _onExpenseTypeChanged(ExpenseTypeChangedEvent event, Emitter<OrderFormState> emit) {
    try {
      emit(state.copyWith(
        expenseType: event.expenseType,
        expenseTypeErrorMessage: event.expenseType == null ? 'Expense type is required.' : null,
      ));
    } catch (e, stackTrace) {
      printBoxed('Error changing expense type: $e \n $stackTrace', 'OrderFormBloc');
      emit(state.copyWith(
        status: FormStatus.error,
        dialogErrorMessage: 'Failed to change expense type.',
      ));
    }
  }

  void _onPaymentMethodChanged(PaymentMethodChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(
      paymentMethod: event.paymentMethod,
      paymentMethodErrorMessage: event.paymentMethod == null ? 'Payment method is required.' : null,
    ));
  }

  void _onReferenceNumberChanged(ReferenceNumberChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(
      referenceNumber: event.referenceNumber,
      referenceNumberErrorMessage:
          event.referenceNumber.isEmpty ? 'Reference number is required.' : null,
    ));
  }

  void _onMemoChanged(MemoChangedEvent event, Emitter<OrderFormState> emit) {
    emit(state.copyWith(memo: event.memo));
  }

  void _onProductAdded(ProductAddedEvent event, Emitter<OrderFormState> emit) {
    final updatedProducts = [...state.products!, const EmptyFormProduct()];
    emit(state.copyWith(products: updatedProducts));
  }

  void _onProductRemoved(ProductRemovedEvent event, Emitter<OrderFormState> emit) {
    final updatedProducts = List<FormProduct>.from(state.products!)..removeAt(event.index);
    emit(state.copyWith(products: updatedProducts));
  }

  void _onProductSelected(ProductSelectedEvent event, Emitter<OrderFormState> emit) {
    final updatedProducts = List<FormProduct>.from(state.products!);
    if (event.index != -1) {
      updatedProducts[event.index] =
          FormProduct.fromProduct(event.product).copyWith(rate: event.product.orderCost, amount: 0);
      emit(state.copyWith(products: updatedProducts));
    }
  }

  void _onProductUpdated(ProductUpdatedEvent event, Emitter<OrderFormState> emit) {
    final updatedProducts = List<FormProduct>.from(state.products!);
    if (event.index != -1) {
      final adjustedRate = event.product.rate * (event.product.conversionFactor ?? 1);
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

  void _onOrderItemAdded(OrderItemAddedEvent event, Emitter<OrderFormState> emit) {
    final updatedOrderItems = [...?state.orderItems, const FormOrderItem()];
    emit(state.copyWith(orderItems: updatedOrderItems));
  }

  void _onOrderItemRemoved(OrderItemRemovedEvent event, Emitter<OrderFormState> emit) {
    final updatedOrderItems = List<FormOrderItem>.from(state.orderItems!)..removeAt(event.index);
    emit(state.copyWith(orderItems: updatedOrderItems));
  }

  void _onOrderItemUpdated(OrderItemUpdatedEvent event, Emitter<OrderFormState> emit) {
    final updatedOrderItems = List<FormOrderItem>.from(state.orderItems!);
    if (event.index != -1) {
      updatedOrderItems[event.index] = event.orderItem;
      final amountDue = updatedOrderItems.fold<double>(
        0,
        (previousValue, element) => previousValue + element.amount,
      );
      emit(state.copyWith(orderItems: updatedOrderItems, amountDue: amountDue));
    }
  }

  Future<void> _onFormSubmitted(FormSubmittedEvent event, Emitter<OrderFormState> emit) async {
    // reset the form key to validate the form
    formKey.currentState?.reset();
    // Emit the button pressed event to handle validation and submission
    if (state.orderType == OrderType.restock) {
      emit(OrderFormState.RestockOrder(null, null));
    } else if (state.orderType == OrderType.expense) {
      emit(OrderFormState.ExpenseOrder(null));
    } else {
      emit(state.copyWith(status: FormStatus.error, dialogErrorMessage: 'Invalid order type.'));
    }
  }

  void _onClearProducts(ClearProductsEvent event, Emitter<OrderFormState> emit) {
    final cleared = <FormProduct>[const EmptyFormProduct()];
    emit(state.copyWith(products: cleared));
  }

  void _onClearOrderItems(ClearOrderItemsEvent event, Emitter<OrderFormState> emit) {
    final cleared = <FormOrderItem>[const FormOrderItem()];
    emit(state.copyWith(orderItems: cleared));
  }

  Future<void> _onSaveExpenseOrderRequest(
    SaveExpenseOrderRequestEvent event,
    Emitter<OrderFormState> emit,
  ) async {
    // First emit validating state to show we're processing
    emit(state.copyWith(status: FormStatus.validating));

    await Future.delayed(Duration.zero);

    /// Checks for Expense Orders
    /// - Payee Name must not be empty
    /// - Order Items must not be empty
    /// - Payment Method must be selected
    /// - Reference Number must not be empty
    /// - Order Date must not be in the future
    /// - All order items must have valid details
    final orderItems = state.orderItems;

    emit(state.copyWith(
      payeeName: state.payeeName,
      payeeNameErrorMessage: state.payeeName.trim().isEmpty ? 'Payee name is required.' : null,
      referenceNumber: state.referenceNumber,
      referenceNumberErrorMessage:
          state.referenceNumber.trim().isEmpty ? 'Reference number is required.' : null,
      paymentMethod: state.paymentMethod,
      paymentMethodErrorMessage: state.paymentMethod == null ? 'Payment method is required.' : null,
      expenseType: state.expenseType,
      expenseTypeErrorMessage: state.expenseType == null ? 'Expense type is required.' : null,
      orderDate: state.orderDate,
      orderDateErrorMessage:
          state.orderDate.isAfter(DateTime.now()) ? 'Order date cannot be in the future.' : null,
    ));

    final orderDateErrorMessage = state.orderDateErrorMessage;
    final payeeNameErrorMessage = state.payeeNameErrorMessage;
    final paymentMethodErrorMessage = state.paymentMethodErrorMessage;
    final referenceNumberErrorMessage = state.referenceNumberErrorMessage;
    final expenseTypeErrorMessage = state.expenseTypeErrorMessage;

    final info = [
      'Order Type: ${state.orderType.name}',
      'Payee Name: ${state.payeeName}',
      'Order Date: ${state.orderDate}',
      'Expense Type: ${state.expenseType?.name ?? 'N/A'}',
      'Payment Method: ${state.paymentMethod?.name ?? 'N/A'}',
      'Reference Number: ${state.referenceNumber}',
      'Memo: ${state.memo ?? 'N/A'}',
      'Order Items: ${state.orderItems}',
      'Amount Due: ${state.amountDue}',
      'Creation Date: ${state.creationDate}',
      'Creator ID: ${state.creatorId ?? 'N/A'}',
    ].map((e) => e.toString()).join('\n -');

    printBoxed('Submitting Expense Order Form: ${info.toString().wrap}', 'CreateExpenseOrderPage');

    // Start validation
    emit(state.copyWith(status: FormStatus.validating));

    // Check if order items are empty
    if (orderItems!.every(
      (item) =>
          (item.description == null || item.description!.isEmpty) &&
          item.quantity <= 0 &&
          item.rate <= 0,
    )) {
      emit(
        state.copyWith(
          status: FormStatus.error,
          orderItems: orderItems
              .map(
                (item) => item.copyWith(
                  errorMessage: 'Order items cannot be empty',
                ),
              )
              .toList(),
          dialogErrorMessage: 'Please add at least one order item.',
        ),
      );
      return;
    }

    // Tag incomplete order items
    final taggedOrderItems = orderItems.map(
      (item) {
        // Only validate if any field has been touched
        if ((item.description != null && item.description!.isNotEmpty) ||
            item.quantity > 0 ||
            item.rate > 0) {
          if (item.description == null || item.description!.isEmpty) {
            return item.copyWith(errorMessage: 'Description cannot be blank');
          } else if (item.quantity <= 0) {
            return item.copyWith(errorMessage: 'Quantity must be greater than 0');
          } else if (item.rate <= 0) {
            return item.copyWith(errorMessage: 'Rate must be greater than 0');
          }
        }
        return item.copyWith(errorMessage: null); // Clear any existing errors
      },
    ).toList();

    if (taggedOrderItems.any((item) => item.errorMessage != null)) {
      return emit(
        state.copyWith(
          status: FormStatus.error,
          orderItems: taggedOrderItems,
          dialogErrorMessage: 'Please fill in all order item details.',
        ),
      );
    }

    // Check required fields
    if (payeeNameErrorMessage != null ||
        paymentMethodErrorMessage != null ||
        referenceNumberErrorMessage != null ||
        expenseTypeErrorMessage != null) {
      return emit(
        state.copyWith(
          status: FormStatus.error,
          dialogErrorMessage: payeeNameErrorMessage ??
              paymentMethodErrorMessage ??
              referenceNumberErrorMessage ??
              expenseTypeErrorMessage ??
              'Please check required fields.',
        ),
      );
    }

    // Check dates
    if (orderDateErrorMessage != null) {
      return emit(
        state.copyWith(
          status: FormStatus.error,
          dialogErrorMessage: 'Please select valid order date.',
        ),
      );
    }

    // If all validation passes, proceed with submission
    emit(state.copyWith(
      dialogErrorMessage: null,
      creationDate: event.creationDate,
      creatorId: event.creatorId,
      status: FormStatus.submitting,
      orderItems: taggedOrderItems, // Clear any previous errors
    ));
  }

  Future<void> _onSaveRestockOrderRequest(
    SaveRestockOrderRequestEvent event,
    Emitter<OrderFormState> emit,
  ) async {
    // First emit validating state to show we're processing
    emit(state.copyWith(status: FormStatus.validating));

    await Future.delayed(Duration.zero);

    /// Checks
    /// - Payee Name must not be empty
    /// - Products must not be empty
    /// - Payment Method must be selected
    /// - Reference Number must not be empty
    /// - Order Date must not be in the future
    /// - All products must have valid details
    final products = state.products;

    emit(state.copyWith(
      payeeName: state.payeeName,
      payeeNameErrorMessage: state.payeeName.trim().isEmpty ? 'Payee name is required.' : null,
      referenceNumber: state.referenceNumber,
      referenceNumberErrorMessage:
          state.referenceNumber.trim().isEmpty ? 'Reference number is required.' : null,
      paymentMethod: state.paymentMethod,
      paymentMethodErrorMessage: state.paymentMethod == null ? 'Payment method is required.' : null,
      orderDate: state.orderDate,
      orderDateErrorMessage:
          state.orderDate.isAfter(DateTime.now()) ? 'Order date cannot be in the future.' : null,
    ));

    final orderDateErrorMessage = state.orderDateErrorMessage;
    final payeeNameErrorMessage = state.payeeNameErrorMessage;
    final paymentMethodErrorMessage = state.paymentMethodErrorMessage;
    final referenceNumberErrorMessage = state.referenceNumberErrorMessage;

    final info = [
      'Order Type: ${state.orderType.name}',
      'Payee Name: ${state.payeeName}',
      'Order Date: ${state.orderDate}',
      'Expense Type: ${state.expenseType?.name ?? 'N/A'}',
      'Payment Method: ${state.paymentMethod?.name ?? 'N/A'}',
      'Reference Number: ${state.referenceNumber}',
      'Memo: ${state.memo ?? 'N/A'}',
      'Products: ${state.products}',
      'Order Items: ${state.orderItems}',
      'Amount Due: ${state.amountDue}',
      'Creation Date: ${state.creationDate}',
      'Creator ID: ${state.creatorId ?? 'N/A'}',
    ].map((e) => e.toString()).join('\n -');

    printBoxed('Submitting Product Form: ${info.toString().wrap}', 'EditProductPage');
    // Start validation
    emit(state.copyWith(status: FormStatus.validating));

    // Check if products are empty
    if (products!.every(
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
        if (product.productId == null) {
          // Only mark as error if some fields are filled but not all
          if (product.quantity > 0 || product.description != null || product.rate > 0) {
            return product.copyWith(errorMessage: 'Item cannot be blank');
          }
        } else if (product.productId == -1) {
          // For expense items, check if all required fields are filled
          if (product.description == null ||
              product.description!.isEmpty ||
              product.quantity <= 0 ||
              product.rate <= 0) {
            return product.copyWith(errorMessage: 'Please fill in all item details');
          }
        }
        return product;
      },
    ).toList();

    if (taggedProducts.any((product) => product.errorMessage == 'Item cannot be blank')) {
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
    if (orderDateErrorMessage != null) {
      return emit(
        state.copyWith(
          status: FormStatus.error,
          dialogErrorMessage: 'Please select valid order date.',
        ),
      );
    }

    // If all validation passes, proceed with submission
    emit(state.copyWith(
      dialogErrorMessage: null,
      creationDate: event.creationDate,
      creatorId: event.creatorId,
      orderId: event.id,
      status: FormStatus.submitting,
    ));
  }
}
