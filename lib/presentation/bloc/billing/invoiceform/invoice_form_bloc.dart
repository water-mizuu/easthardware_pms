import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/models/form_product.dart';
import 'package:equatable/equatable.dart';

part 'invoice_form_event.dart';
part 'invoice_form_state.dart';

class InvoiceFormBloc extends Bloc<InvoiceFormEvent, InvoiceFormState> {
  InvoiceFormBloc() : super(InvoiceFormState()) {
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

    emit(state.copyWith(
      discount: event.discount,
      amountDue: amountDue,
    ));
  }

  void _onDiscountTypeChanged(DiscountTypeChangedEvent event, Emitter<InvoiceFormState> emit) {
    final subtotal = state.subtotal ?? 0;
    final discountAmount = state.discount ?? 0;
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
    if (index != -1) {
      updatedProducts[index] = event.product.copyWith(
        quantity: 0,
        rate: event.product.rate,
      );
      emit(state.copyWith(products: updatedProducts));
    }
  }

  void _onProductUpdated(ProductUpdatedEvent event, Emitter<InvoiceFormState> emit) {
    final adjustedRate = event.product.rate * (event.product.conversionFactor ?? 1);

    final adjustedProduct = event.product.copyWith(
      rate: adjustedRate,
      amount: adjustedRate * event.product.quantity,
      errorMessage: (event.reference != null && event.reference!.quantity < event.product.quantity)
          ? 'Item quantity exceeds available stock.'
          : null,
    );

    final index = event.index;
    final updatedProducts = List<FormProduct>.from(state.products);

    if (index != -1) {
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

  Future<void> _onFormButtonPressed(
    SaveInvoiceRequestEvent event,
    Emitter<InvoiceFormState> emit,
  ) async {
    await Future.delayed(Duration.zero);

    /// Checks
    /// - Products must not be empty
    /// - All products must have Id
    final products = state.products;
    emit(state.copyWith(status: FormStatus.validating, errorMessage: null));
    if (products.every(
      (product) =>
          product.productId == null &&
          product.description == null &&
          product.quantity <= 0 &&
          product.rate <= 0,
    )) {
      emit(
        state.copyWith(
          errorMessage: 'Please add at least one product.',
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
        if (product.productId == null &&
            (product.quantity > 0 || product.description != null || product.rate > 0)) {
          return product.copyWith(errorMessage: 'Item cannot be blank');
        }
        return product;
      },
    ).toList();

    if (taggedProducts.any((product) => product.errorMessage == 'Item cannot be blank')) {
      emit(
        state.copyWith(
          status: FormStatus.error,
          products: taggedProducts,
          errorMessage: 'Please fill in all product details.',
        ),
      );
      await Future.delayed(Duration.zero);
      return emit(state.copyWith(status: FormStatus.initial));
    }

    if (state.invoiceDateErrorMessage != null || state.dueDateErrorMessage != null) {
      emit(
        state.copyWith(
          status: FormStatus.error,
          errorMessage: 'Please select valid invoice and due dates.',
        ),
      );
    }

    return emit(
      state.copyWith(
        errorMessage: null,
        creationDate: event.creationDate,
        creatorId: event.creatorId,
        invoiceId: event.invoiceId,
        status: FormStatus.submitting,
        action: event.action,
      ),
    );
  }

  void _onDialogBoxClosed(DialogBoxClosedEvent event, Emitter<InvoiceFormState> emit) {
    emit(state.copyWith(status: FormStatus.initial));
  }

  Future<void> _onFormSubmitted(FormSubmittedEvent event, Emitter<InvoiceFormState> emit) async {
    emit(state.copyWith(status: FormStatus.submitted));
    await Future.delayed(Duration.zero);
    return emit(InvoiceFormState());
  }
}
