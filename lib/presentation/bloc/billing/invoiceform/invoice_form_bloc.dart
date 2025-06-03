import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/models/form_product.dart';
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
    on<ProductAddedEvent>(_onProductAdded);
    on<ProductSelectedEvent>(_onProductSelected);
    on<ProductRemovedEvent>(_onProductRemoved);
    on<ProductUpdatedEvent>(_onProductUpdated);
    on<FormButtonPressedEvent>(_onFormButtonPressed);
  }

  void _onCustomerNameChanged(CustomerNameChangedEvent event, Emitter<InvoiceFormState> emit) {
    emit(state.copyWith(customerName: event.customerName));
  }

  void _onInvoiceDateChanged(InvoiceDateChangedEvent event, Emitter<InvoiceFormState> emit) {
    emit(state.copyWith(invoiceDate: event.invoiceDate));
  }

  void _onDueDateChanged(DueDateChangedEvent event, Emitter<InvoiceFormState> emit) {
    emit(state.copyWith(dueDate: event.dueDate));
  }

  void _onMemoChanged(MemoChangedEvent event, Emitter<InvoiceFormState> emit) {
    emit(state.copyWith(memo: event.memo));
  }

  void _onDiscountChanged(DiscountChangedEvent event, Emitter<InvoiceFormState> emit) {
    emit(state.copyWith(discount: event.discount));
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

  void _onProductSelected(ProductSelectedEvent event, Emitter<InvoiceFormState> emit) {
    print("Selected: ${event.product}");
    final index = event.index;
    final selectedProduct = event.product;
    final updatedProducts = List<FormProduct>.from(state.products);
    if (index != -1) {
      updatedProducts[index] = FormProduct.fromProduct(selectedProduct);
      emit(state.copyWith(products: updatedProducts));
    }
  }

  void _onProductUpdated(ProductUpdatedEvent event, Emitter<InvoiceFormState> emit) {
    final index = event.index;
    final updatedProducts = List<FormProduct>.from(state.products);
    if (index != -1) {
      updatedProducts[index] = event.product;
      emit(state.copyWith(products: updatedProducts));
    }
  }

  void _onFormButtonPressed(FormButtonPressedEvent event, Emitter<InvoiceFormState> emit) {
    // TODO:
  }
}
