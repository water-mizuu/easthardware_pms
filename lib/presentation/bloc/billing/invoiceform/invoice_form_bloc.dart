import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart'
    show FormStatus, InvoicePostAction, DiscountType;
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/models/form_product.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'invoice_form_event.dart';
part 'invoice_form_state.dart';

class InvoiceFormBloc extends Bloc<InvoiceFormEvent, InvoiceFormState> {
  InvoiceFormBloc([InvoiceFormState? initialState]) : super(initialState ?? InvoiceFormState()) {
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
    on<SaveInvoiceRequestEvent>(_onFormButtonPressed);
    on<FormSubmittedEvent>(_onFormSubmitted);
    on<DialogBoxClosedEvent>(_onDialogBoxClosed);
  }
  InvoiceFormBloc.fromExistingInvoice(Invoice invoice, List<InvoiceProduct> products)
      : this(InvoiceFormState.fromExistingInvoice(invoice, products));

  @override
  onEvent(InvoiceFormEvent event) {
    super.onEvent(event);

    printBoxed(event, "InformFormBloc");
  }

  void _onCustomerNameChanged(CustomerNameChangedEvent event, Emitter<InvoiceFormState> emit) {
    emit(state.copyWith(customerName: event.customerName));
  }

  void _onInvoiceDateChanged(InvoiceDateChangedEvent event, Emitter<InvoiceFormState> emit) {
    emit(
      state.copyWith(
        invoiceDate: event.invoiceDate,
        invoiceDateErrorMessage: event.invoiceDate.isAfter(DateTime.now())
            ? 'Invoice date cannot be in the future.'
            : null,
      ),
    );
  }

  void _onDueDateChanged(DueDateChangedEvent event, Emitter<InvoiceFormState> emit) {
    emit(
      state.copyWith(
        dueDate: event.dueDate,
        dueDateErrorMessage: event.dueDate.isBefore(state.invoiceDate)
            ? 'Due date cannot be before invoice date.'
            : null,
      ),
    );
  }

  void _onMemoChanged(MemoChangedEvent event, Emitter<InvoiceFormState> emit) {
    emit(state.copyWith(memo: event.memo));
  }

  void _onDiscountChanged(DiscountChangedEvent event, Emitter<InvoiceFormState> emit) {
    final subtotal = state.subtotal ?? 0;
    final amountDue = (subtotal) -
        (state.discountType == DiscountType.percentage
            ? (subtotal * event.discount / 100)
            : event.discount);

    if (event.discount > 100 && state.discountType == DiscountType.percentage) {
      emit(state.copyWith(
        discount: event.discount,
        discountErrorMessage: 'Discount percentage cannot exceed 100%.',
      ));
      printBoxed(state.discountErrorMessage);
      return;
    }
    if (event.discount > subtotal && state.discountType == DiscountType.value) {
      emit(state.copyWith(
        discount: event.discount,
        discountErrorMessage: 'Discount amount cannot exceed subtotal.',
      ));
      printBoxed(state.discountErrorMessage);
      return;
    }

    emit(state.copyWith(
      discount: event.discount,
      amountDue: amountDue,
      discountErrorMessage: null,
    ));
  }

  void _onDiscountTypeChanged(DiscountTypeChangedEvent event, Emitter<InvoiceFormState> emit) {
    final subtotal = state.subtotal ?? 0;
    final discountAmount = state.discount ?? 0;
    final amountDue = (subtotal) -
        (event.discountType == DiscountType.percentage
            ? (subtotal * discountAmount / 100)
            : discountAmount);
    if (event.discountType == DiscountType.percentage && discountAmount > 100) {
      emit(state.copyWith(
        discountType: event.discountType,
        discountErrorMessage: 'Discount percentage cannot exceed 100%.',
      ));
      printBoxed(state.discountErrorMessage);
      return;
    }
    if (event.discountType == DiscountType.value && discountAmount > subtotal) {
      emit(state.copyWith(
        discountType: event.discountType,
        discountErrorMessage: 'Discount amount cannot exceed subtotal.',
      ));
      printBoxed(state.discountErrorMessage);
      return;
    }

    return emit(state.copyWith(
      discountType: event.discountType,
      amountDue: amountDue,
      discountErrorMessage: null,
    ));
  }

  void _onProductAdded(ProductAddedEvent event, Emitter<InvoiceFormState> emit) {
    final updatedProducts = List<FormProduct>.from(state.products)..add(const EmptyFormProduct());
    emit(state.copyWith(products: updatedProducts));
  }

  void _onProductRemoved(ProductRemovedEvent event, Emitter<InvoiceFormState> emit) {
    final index = event.index;
    final updatedProducts = List<FormProduct>.from(state.products)..removeAt(index);
    emit(state.copyWith(products: updatedProducts));
  }

  void _onProductsCleared(ProductsClearedEvent event, Emitter<InvoiceFormState> emit) {
    final updatedProducts = <FormProduct>[const EmptyFormProduct()];
    emit(state.copyWith(products: updatedProducts));
  }

  void _onProductSelected(ProductSelectedEvent event, Emitter<InvoiceFormState> emit) {
    final index = event.index;
    final updatedProducts = List<FormProduct>.from(state.products);
    if (index != -1) {
      updatedProducts[index] = event.product.copyWith(
        quantity: 0,
        rate: event.product.rate,
      );
      emit(state.copyWith(products: updatedProducts));
    }
  }

  void _onProductUpdated(ProductUpdatedEvent event, Emitter<InvoiceFormState> emit) {
    // printBoxed('Conversion Factor: ${event.product.conversionFactor}');

    final adjustedRate = event.product.rate * (event.product.conversionFactor ?? 1);

    final adjustedProduct = event.product.copyWith(
      rate: adjustedRate,
      amount: adjustedRate * event.product.quantity,
      errorMessage: (event.reference != null && event.reference!.quantity < event.product.quantity)
          ? 'Item quantity exceeds available stock.'
          : null,
    );

    final index = event.index;
    if (index == -1) return;

    printBoxed(
      const JsonEncoder.withIndent("  ").convert(adjustedProduct.toMap()),
      "Adjusted Product",
    );
    final updatedProducts = List<FormProduct>.from(state.products)..[index] = adjustedProduct;

    /// Compute the new subtotal, discount, and amount due.
    final subtotal = updatedProducts.map((e) => e.amount).fold(0.0, (acc, cur) => acc + cur);
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

  Future<void> _onFormButtonPressed(
    SaveInvoiceRequestEvent event,
    Emitter<InvoiceFormState> emit,
  ) async {
    await Future.delayed(Duration.zero);

    /// Checks
    /// - Products must not be empty
    final products = state.products;
    final invoiceDateErrorMessage = state.invoiceDateErrorMessage;
    final dueDateErrorMessage = state.dueDateErrorMessage;
    final discountErrorMessage = state.discountErrorMessage;

    emit(state.copyWith(status: FormStatus.validating, dialogErrorMessage: null));
    if (products.every(
      (product) =>
          product.productId == null &&
          product.description == null &&
          product.quantity <= 0 &&
          product.rate <= 0,
    )) {
      emit(
        state.copyWith(
          dialogErrorMessage: 'Please add at least one product.',
          status: FormStatus.error,
          products: products
              .map(
                (product) => product.copyWith(
                  errorMessage: 'Invoice items cannot be empty',
                ),
              )
              .toList(),
        ),
      );
      await Future.delayed(Duration.zero);
      return emit(state.copyWith(status: FormStatus.initial));
    }

    final taggedProducts = products.map(
      (product) {
        if (kDebugMode) {
          print(const JsonEncoder.withIndent("  ").convert(product.toMap()));
        }
        if (product.productId == null) {
          return product.copyWith(errorMessage: 'Item cannot be blank');
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

    if (invoiceDateErrorMessage != null || dueDateErrorMessage != null) {
      return emit(
        state.copyWith(
          status: FormStatus.error,
          dialogErrorMessage: 'Please select valid invoice and due dates.',
        ),
      );
    }
    if (discountErrorMessage != null) {
      return emit(
        state.copyWith(
          status: FormStatus.error,
          dialogErrorMessage: discountErrorMessage,
        ),
      );
    }

    if (taggedProducts
        .any((product) => product.errorMessage == 'Item quantity exceeds available stock.')) {
      return emit(
        state.copyWith(
          status: FormStatus.error,
          dialogErrorMessage: 'Item quantity exceeds available stock.',
        ),
      );
    }

    emit(
      state.copyWith(
        dialogErrorMessage: null,
        creationDate: event.creationDate,
        creatorId: event.creatorId,
        status: FormStatus.submitting,
        action: event.action,
      ),
    );

    return;
  }

  void _onDialogBoxClosed(
    DialogBoxClosedEvent event,
    Emitter<InvoiceFormState> emit,
  ) {
    printBoxed('Dialog box closed');
    emit(state.copyWith(status: FormStatus.initial));
    printBoxed(state.copyWith(status: FormStatus.initial));
  }

  Future<void> _onFormSubmitted(FormSubmittedEvent event, Emitter<InvoiceFormState> emit) async {
    emit(state.copyWith(status: FormStatus.submitted));
    await Future.delayed(Duration.zero);
    return emit(InvoiceFormState());
  }
}
