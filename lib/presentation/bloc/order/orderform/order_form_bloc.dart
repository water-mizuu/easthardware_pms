import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart' show DiscountType, FormStatus, OrderType;
import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/order_item.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/domain/repository/order_repository.dart';
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
  OrderFormBloc(super.state, {OrderRepository? orderRepository})
      : _orderRepository = orderRepository,
        formKey = GlobalKey<FormState>() {
    on<PayeeNameChangedEvent>(_onPayeeNameChanged);
    on<OrderDateChangedEvent>(_onOrderDateChanged);
    on<ExpenseTypeChangedEvent>(_onExpenseTypeChanged);
    on<PaymentMethodChangedEvent>(_onPaymentMethodChanged);
    on<ReferenceNumberChangedEvent>(_onReferenceNumberChanged);
    on<MemoChangedEvent>(_onMemoChanged);
    on<ProductAddedEvent>(_onProductAdded);
    on<ProductRemovedEvent>(_onProductRemoved);
    // on<ProductSelectedEvent>(_onProductSelected);
    on<ProductUpdatedEvent>(_onProductUpdated);
    on<OrderItemAddedEvent>(_onOrderItemAdded);
    on<OrderItemRemovedEvent>(_onOrderItemRemoved);
    on<OrderItemUpdatedEvent>(_onOrderItemUpdated);
    on<ClearOrderItemsEvent>(_onClearOrderItems);
    on<FormSubmittedEvent>(_onFormSubmitted);
    on<ClearProductsEvent>(_onClearProducts);
    on<SaveRestockOrderRequestEvent>(_onSaveRestockOrderRequest);
    on<SaveExpenseOrderRequestEvent>(_onSaveExpenseOrderRequest);
    on<LoadExistingRestockOrderEvent>(_onLoadExistingRestockOrder); // Add this line
    on<LoadExistingExpenseOrderEvent>(_onLoadExistingExpenseOrder); // Add this line
  }

  factory OrderFormBloc.fromRestockOrder(Product? product, {OrderRepository? orderRepository}) {
    return OrderFormBloc(
      OrderFormState.restockOrder(product, null),
      orderRepository: orderRepository,
    );
  }
  factory OrderFormBloc.fromExpenseOrder({OrderRepository? orderRepository}) {
    return OrderFormBloc(
      OrderFormState.expenseOrder(null),
      orderRepository: orderRepository,
    );
  }
  factory OrderFormBloc.fromExistingRestockOrder(
    Order order,
    List<FormProduct> products,
    PaymentMethod paymentMethod,
    ExpenseType expenseType, {
    OrderRepository? orderRepository,
  }) {
    // Create a basic OrderFormBloc
    final bloc = OrderFormBloc(
      OrderFormState.fromExistingRestockOrder(
        order,
        products,
        paymentMethod,
        expenseType,
      ),
      orderRepository: orderRepository,
    );
    // If orderId is provided, we'll load the order details
    // in the EditRestockOrderPage instead of here
    return bloc;
  }
  factory OrderFormBloc.fromExistingExpenseOrder(int? orderId, {OrderRepository? orderRepository}) {
    // TODO: Implement
    return OrderFormBloc(
      OrderFormState.expenseOrder(orderId),
      orderRepository: orderRepository,
    );
  }
  final OrderRepository? _orderRepository;

  final GlobalKey<FormState> formKey;

  // @override
  // void onEvent(OrderFormEvent event) {
  //   // ignore: invalid_use_of_visible_for_testing_member
  //   super.onEvent(event);

  //   printBoxed(event, 'OrderFormBloc');
  // }

  @override
  void emit(OrderFormState state) {
    // ignore: invalid_use_of_visible_for_testing_member
    super.emit(state);

    // printBoxed(const JsonEncoder.withIndent('. ').convert(state.toMap()), 'OrderFormBloc');
  }

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
      // printBoxed("Changing expense type to: ${event.expenseType!.id}");
      emit(state.copyWith(
        expenseType: event.expenseType,
        expenseTypeErrorMessage: event.expenseType == null ? 'Expense type is required.' : null,
      ));
    } catch (e) {
      // printBoxed('Error changing expense type: $e \n $stackTrace', 'OrderFormBloc');
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
    if (updatedProducts.isEmpty) {
      updatedProducts.add(const EmptyFormProduct());
    }

    emit(state.copyWith(products: updatedProducts));
  }

  // void _onProductSelected(ProductSelectedEvent event, Emitter<OrderFormState> emit) {
  //   final updatedProducts = List<FormProduct>.from(state.products!);
  //   if (event.index != -1) {
  //     updatedProducts[event.index] =
  //         FormProduct.fromProduct(event.product).copyWith(rate: event.product.orderCost, amount: 0);
  //     emit(state.copyWith(products: updatedProducts));
  //   }
  // }
  void _onProductUpdated(ProductUpdatedEvent event, Emitter<OrderFormState> emit) {
    final updatedProducts = List<FormProduct>.from(state.products!);
    if (event.index != -1) {
      final adjustedRate = event.product.rate * (event.product.conversionFactor ?? 1);

      // Debug: Log product update details to trace description changes
      // print('[ProductUpdatedEvent] Updating product at index ${event.index}:');
      // print('[ProductUpdatedEvent] Product: ${event.product.productName}');
      // print(
      // '[ProductUpdatedEvent] Description before: "${updatedProducts[event.index].description}"');
      // print('[ProductUpdatedEvent] Description being set: "${event.product.description}"');

      // Always calculate amount based on the provided product's quantity and the adjusted rate
      // This ensures the amount is always consistent with the latest changes
      final adjustedProduct = event.product.copyWith(
        rate: adjustedRate,
        amount: adjustedRate * event.product.quantity,
      );

      updatedProducts[event.index] = adjustedProduct;
      final amountDue = updatedProducts.fold<double>(
        0,
        (previousValue, element) => previousValue + (element.amount),
      );

      // printBoxed(
      //   'Updated product at index ${event.index} with amount:\n$adjustedProduct',
      //   'OrderFormBloc',
      // );
      emit(state.copyWith(products: updatedProducts, amountDue: amountDue));
    }
  }

  void _onOrderItemAdded(OrderItemAddedEvent event, Emitter<OrderFormState> emit) {
    final updatedOrderItems = [...?state.orderItems, const FormOrderItem()];
    emit(state.copyWith(orderItems: updatedOrderItems));
  }

  void _onOrderItemRemoved(OrderItemRemovedEvent event, Emitter<OrderFormState> emit) {
    final updatedOrderItems = List<FormOrderItem>.from(state.orderItems!)..removeAt(event.index);
    if (updatedOrderItems.isEmpty) {
      updatedOrderItems.add(const EmptyFormOrderItem());
    }
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
      emit(OrderFormState.restockOrder(null, null));
    } else if (state.orderType == OrderType.expense) {
      emit(OrderFormState.expenseOrder(null));
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

    // Fetch existing reference numbers for validation, excluding the current order if we're editing
    final existingReferenceNumbers =
        await _getExistingReferenceNumbers(excludeOrderId: state.orderId);

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
      payeeNameErrorMessage: state.payeeName.trim().isEmpty //
          ? 'Payee name is required.'
          : null,
      referenceNumber: state.referenceNumber,
      referenceNumberErrorMessage: state.referenceNumber.trim().isEmpty //
          ? 'Reference number is required.'
          : existingReferenceNumbers.contains(state.referenceNumber.trim())
              ? 'Reference number already exists.'
              : null,
      paymentMethod: state.paymentMethod,
      paymentMethodErrorMessage: state.paymentMethod == null //
          ? 'Payment method is required.'
          : null,
      expenseType: state.expenseType,
      expenseTypeErrorMessage: state.expenseType == null //
          ? 'Expense type is required.'
          : null,
      orderDate: state.orderDate,
      orderDateErrorMessage: state.orderDate.isAfter(DateTime.now()) //
          ? 'Order date cannot be in the future.'
          : null,
    ));

    final orderDateErrorMessage = state.orderDateErrorMessage;
    final payeeNameErrorMessage = state.payeeNameErrorMessage;
    final paymentMethodErrorMessage = state.paymentMethodErrorMessage;
    final referenceNumberErrorMessage = state.referenceNumberErrorMessage;
    final expenseTypeErrorMessage = state.expenseTypeErrorMessage;

    // final info = [
    //   'Order Type: ${state.orderType.name}',
    //   'Payee Name: ${state.payeeName}',
    //   'Order Date: ${state.orderDate}',
    //   'Expense Type: ${state.expenseType?.name ?? 'N/A'}',
    //   'Payment Method: ${state.paymentMethod?.name ?? 'N/A'}',
    //   'Reference Number: ${state.referenceNumber}',
    //   'Memo: ${state.memo ?? 'N/A'}',
    //   'Order Items: ${state.orderItems}',
    //   'Amount Due: ${state.amountDue}',
    //   'Creation Date: ${state.creationDate}',
    //   'Creator ID: ${state.creatorId ?? 'N/A'}',
    // ].map((e) => e.toString()).join('\n -');

    // printBoxed('Submitting Expense Order Form: ${info.toString().wrap}', 'CreateExpenseOrderPage');

    // Start validation
    emit(state.copyWith(status: FormStatus.validating));

    // Check if order items are empty
    if (orderItems!.every(
      (item) => item.quantity <= 0 && item.rate <= 0,
    )) {
      emit(
        state.copyWith(
          status: FormStatus.error,
          orderItems: orderItems
              .map((item) => item.copyWith(errorMessage: 'Order items cannot be empty'))
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
        if (item.description == null || item.description!.isEmpty) {
          // If description is empty, mark as error
          return item.copyWith(errorMessage: 'Item cannot be blank');
        } else if (item.quantity <= 0) {
          // If quantity is zero or negative, mark as error
          return item.copyWith(errorMessage: 'Item cannot be blank');
        } else if (item.rate <= 0) {
          // If rate is zero or negative, mark as error
          return item.copyWith(errorMessage: 'Item cannot be blank');
        } else if (item.name == null || item.name!.isEmpty) {
          // If name is empty, mark as error
          return item.copyWith(errorMessage: 'Item cannot be blank');
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
                'Please check required fields.'),
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
    print("Expense Order Emitting...");
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

    // Fetch existing reference numbers for validation, excluding the current order if we're´ editing
    final existingReferenceNumbers =
        await _getExistingReferenceNumbers(excludeOrderId: state.orderId);

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
      referenceNumberErrorMessage: state.referenceNumber.trim().isEmpty
          ? 'Reference number is required.'
          : existingReferenceNumbers.contains(state.referenceNumber.trim())
              ? 'Reference number already exists.'
              : null,
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
                  errorMessage: 'Please add at least one product.',
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
        } else if (product.quantity <= 0) {
          return product.copyWith(errorMessage: 'Item cannot be blank');
        } else if (product.rate <= 0) {
          return product.copyWith(errorMessage: 'Item cannot be blank');
        } else if (product.description != null && product.description!.isEmpty) {
          return product.copyWith(errorMessage: 'Item cannot be blank');
        } else {
          return product.copyWith(errorMessage: null); // Clear any existing errors
        }
        return product;
      },
    ).toList();

    if (taggedProducts.any((product) => product.errorMessage == 'Item cannot be blank')) {
      return emit(
        state.copyWith(
          status: FormStatus.error,
          products: taggedProducts,
          dialogErrorMessage: 'Please fill in all product\'s required details.',
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
      status: FormStatus.submitting,
      // Ensure we maintain the orderId in the state for update operations
      orderId: state.orderId,
    ));
  }

  void _onLoadExistingRestockOrder(
      LoadExistingRestockOrderEvent event, Emitter<OrderFormState> emit) {
    final order = event.order;
    final expenseType = event.expenseType;
    final paymentMethod = event.paymentMethod;
    final orderProducts = event.products;

    // Debug: Log order products being loaded into the form
    printBoxed('[OrderFormBloc] Loading order products:', '_onLoadExistingRestockOrder');
    for (final product in orderProducts) {
      printBoxed(
          '[OrderFormBloc] Product: ${product.productName}, description: "${product.description}"',
          'OrderProducts');
    }

    // Instead of creating new FormProduct instances, modify the existing state products
    // to ensure we don't lose any data that might have been set correctly
    final List<FormProduct> formProducts;

    // If we have existing products in state, use those as a base and update them
    if (state.products != null && state.products!.isNotEmpty) {
      // Create a map of existing form products by productId for quick lookup
      final existingProductsMap = {
        for (final p in state.products!)
          if (p.productId != null) p.productId: p
      };

      formProducts = orderProducts.map((product) {
        // Check if we have an existing form product for this product ID
        final existingProduct = existingProductsMap[product.productId];

        // If we have an existing product, update it with values from the order product
        // but preserve any fields that might be more accurate in the existing product
        if (existingProduct != null) {
          return existingProduct.copyWith(
            productName: product.productName,
            description: product.description ?? existingProduct.description,
            quantity: product.quantity,
            unitId: product.secondaryUnit,
            conversionFactor: product.conversionFactor,
            rate: product.rate,
            amount: product.amount,
          );
        }

        // If no existing product, create a new FormProduct
        return FormProduct(
          productId: product.productId,
          productName: product.productName,
          description: product.description, // Preserve exact description from database
          quantity: product.quantity,
          unit: product.secondaryUnit?.toString() ?? '', // Will be updated by UI components
          unitId: product.secondaryUnit,
          conversionFactor: product.conversionFactor,
          rate: product.rate,
          amount: product.amount,
          discountType: DiscountType.value,
        );
      }).toList();
    } else {
      // If no existing products, create new FormProduct instances
      formProducts = orderProducts.map((product) {
        return FormProduct(
          productId: product.productId,
          productName: product.productName,
          description: product.description,
          quantity: product.quantity,
          unit: product.secondaryUnit?.toString() ?? '',
          unitId: product.secondaryUnit,
          conversionFactor: product.conversionFactor,
          rate: product.rate,
          amount: product.amount,
          discountType: DiscountType.value,
        );
      }).toList();
    }

    // Update the state with the loaded order data
    emit(state.copyWith(
      orderId: order.id,
      payeeName: order.payeeName,
      orderDate: order.orderDate,
      expenseType: expenseType,
      paymentMethod: paymentMethod,
      referenceNumber: order.referenceNumber ?? '',
      memo: order.memo ?? '',
      amountDue: order.amountDue,
      creationDate: order.creationDate,
      creatorId: order.creatorId,
      products: formProducts,
      status: FormStatus.initial,
    ));
  }

  void _onLoadExistingExpenseOrder(
      LoadExistingExpenseOrderEvent event, Emitter<OrderFormState> emit) {
    final order = event.order;
    final expenseType = event.expenseType;
    final paymentMethod = event.paymentMethod;
    final orderItems = event.orderItems;

    // Convert OrderItem list to FormOrderItem list
    final formOrderItems = orderItems.map((item) {
      return FormOrderItem(
        name: item.name,
        description: item.description ?? '',
        quantity: item.quantity,
        rate: item.rate,
        amount: item.amount,
      );
    }).toList();

    // Update the state with the loaded order data
    emit(state.copyWith(
      orderId: order.id,
      payeeName: order.payeeName,
      orderDate: order.orderDate,
      expenseType: expenseType,
      paymentMethod: paymentMethod,
      referenceNumber: order.referenceNumber ?? '',
      memo: order.memo ?? '',
      amountDue: order.amountDue,
      creationDate: order.creationDate,
      creatorId: order.creatorId,
      orderItems: formOrderItems,
      status: FormStatus.initial,
    ));
  }

  // Method to get all existing reference numbers from the repository, excluding the current order's reference number
  Future<List<String>> _getExistingReferenceNumbers({int? excludeOrderId}) async {
    if (_orderRepository == null) {
      return [];
    }

    try {
      // Get all orders from the repository
      final orders = await _orderRepository.getAllOrders();

      // Extract the reference numbers from orders, excluding the current order if provided
      final existingRefNumbers = orders
          .where((order) => order.id != excludeOrderId) // Exclude the current order if editing
          .map((order) => order.referenceNumber)
          .where((refNum) => refNum != null && refNum.isNotEmpty)
          .map((refNum) => refNum!)
          .toList();

      return existingRefNumbers;
    } catch (e) {
      // printBoxed('Error fetching reference numbers: $e \n $stackTrace', 'OrderFormBloc');
      return [];
    }
  }
}
