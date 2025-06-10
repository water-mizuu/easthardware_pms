import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/presentation/models/form_product.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

part 'invoice_form_event.dart';
part 'invoice_form_state.dart';

class InvoiceFormBloc extends Bloc<InvoiceFormEvent, InvoiceFormState> {
  final GlobalKey<FormState> formKey;
  InvoiceFormBloc()
      : formKey = GlobalKey<FormState>(),
        super(InvoiceFormState()) {
    on<CustomerNameChangedEvent>(_onCustomerNameChanged);
    on<InvoiceDateChangedEvent>(_onInvoiceDateChanged);
    on<DueDateChangedEvent>(_onDueDateChanged);
    on<MemoChangedEvent>(_onMemoChanged);
    on<DiscountChangedEvent>(_onDiscountChanged);
    on<DiscountTypeChangedEvent>(_onDiscountTypeChanged);
    on<ProductAddedEvent>(_onProductAdded);
    on<ProductSelectedEvent>(_onProductSelected);
    on<ProductRemovedEvent>(_onProductRemoved);
    on<ProductsClearedEvent>(_onProductsCleared);
    on<ProductUpdatedEvent>(_onProductUpdated);
    on<FormButtonPressedEvent>(_onFormButtonPressed);
  }

  void _onCustomerNameChanged(CustomerNameChangedEvent event, Emitter<InvoiceFormState> emit) {
    emit(state.copyWith(customerName: event.customerName));
  }

  void _onInvoiceDateChanged(InvoiceDateChangedEvent event, Emitter<InvoiceFormState> emit) {
    // Ensure that the invoice date is not in the future
    if (event.invoiceDate.isAfter(DateTime.now())) {
      emit(state.copyWith(
        invoiceDateErrorMessage: 'Invoice date cannot be in the future.',
      ));
      return;
    }
    // Clear any previous error message
    emit(state.copyWith(invoiceDateErrorMessage: null, invoiceDate: event.invoiceDate));
  }

  void _onDueDateChanged(DueDateChangedEvent event, Emitter<InvoiceFormState> emit) {
    // Ensure that the due date is not before the invoice date
    if (event.dueDate.isBefore(state.invoiceDate)) {
      emit(state.copyWith(
        dueDateErrorMessage: 'Due date cannot be before the invoice date.',
      ));
      return;
    }
    emit(state.copyWith(dueDate: event.dueDate, dueDateErrorMessage: null));
  }

  void _onMemoChanged(MemoChangedEvent event, Emitter<InvoiceFormState> emit) {
    emit(state.copyWith(memo: event.memo));
  }

  void _onDiscountChanged(DiscountChangedEvent event, Emitter<InvoiceFormState> emit) {
    final subtotal = state.subtotal ?? 0.0;
    final amountDue = (subtotal) -
        (state.discountType == DiscountType.percentage
            ? (subtotal * event.discount / 100)
            : event.discount);

    emit(state.copyWith(
      discount: event.discount,
      amountDue: amountDue,
    ));
  }

  void _onDiscountTypeChanged(DiscountTypeChangedEvent event, Emitter<InvoiceFormState> emit) {
    final subtotal = state.subtotal ?? 0.0;
    final discountAmount = state.discount ?? 0.0;
    final amountDue = (subtotal) -
        (event.discountType == DiscountType.percentage
            ? (subtotal * discountAmount / 100)
            : discountAmount);
    return emit(state.copyWith(discountType: event.discountType, amountDue: amountDue));
  }

  void _onProductAdded(ProductAddedEvent event, Emitter<InvoiceFormState> emit) {
    final updatedProducts = List<FormProduct>.from(state.products)..add(EmptyFormProduct());
    emit(state.copyWith(products: updatedProducts));
  }

  void _onProductRemoved(ProductRemovedEvent event, Emitter<InvoiceFormState> emit) {
    final index = event.index;
    final updatedProducts = List<FormProduct>.from(state.products)..removeAt(index);
    emit(state.copyWith(products: updatedProducts));
  }

  void _onProductsCleared(ProductsClearedEvent event, Emitter<InvoiceFormState> emit) {
    final updatedProducts = <FormProduct>[EmptyFormProduct()];
    emit(state.copyWith(products: updatedProducts));
  }

  void _onProductSelected(ProductSelectedEvent event, Emitter<InvoiceFormState> emit) {
    final index = event.index;
    final updatedProducts = List<FormProduct>.from(state.products);
    // printBoxed('''
    // Product Selected:
    // Id: ${event.product.productId}
    // Name: ${event.product.productName}
    // Description: ${event.product.description}
    // Quantity: ${event.product.quantity}
    // Unit: ${event.product.unit}
    // Conversion Factor: ${event.product.conversionFactor}
    // Rate: ${event.product.rate}
    // Amount: ${event.product.amount}
    // ''', 'InvoiceFormBloc');
    if (index != -1) {
      updatedProducts[index] = event.product.copyWith(
        quantity: 0,
        rate: event.product.rate,
      );
      emit(state.copyWith(products: updatedProducts));
    }
  }

  void _onProductUpdated(ProductUpdatedEvent event, Emitter<InvoiceFormState> emit) {
    final adjustedRate = event.product.rate * (event.product.conversionFactor ?? 1.0);
    // printBoxed('Adjusted Rate: $adjustedRate', 'InvoiceFormBloc');
    final adjustedProduct = event.product.copyWith(
      rate: adjustedRate,
      amount: adjustedRate * event.product.quantity,
    );
    final index = event.index;
    final updatedProducts = List<FormProduct>.from(state.products);
    //print all fields in one box

    if (index != -1) {
      printBoxed('''
      Product Updated:
      Id: ${adjustedProduct.productId}
      Name: ${adjustedProduct.productName}
      Description: ${adjustedProduct.description}
      Quantity: ${adjustedProduct.quantity}
      Unit: ${adjustedProduct.unit}
      Conversion Factor: ${adjustedProduct.conversionFactor}
      Rate: ${adjustedProduct.rate}
      Amount: ${adjustedProduct.amount}
      ''', 'InvoiceFormBloc');

      updatedProducts[index] = adjustedProduct;

      final subtotal = updatedProducts.fold<double>(
        0,
        (previousValue, element) => previousValue + (element.amount),
      );
      final discountAmount = state.discountType == DiscountType.percentage
          ? (subtotal * (state.discount ?? 0) / 100)
          : (state.discount ?? 0);
      final amountDue = subtotal - discountAmount;

      emit(
        state.copyWith(
          products: updatedProducts,
          subtotal: subtotal,
          amountDue: amountDue,
        ),
      );
    }
  }

  void _onFormButtonPressed(FormButtonPressedEvent event, Emitter<InvoiceFormState> emit) {
    // TODO:
  }
}
