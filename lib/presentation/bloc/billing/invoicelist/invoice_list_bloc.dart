import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/repository/invoice_product_repository.dart';
import 'package:easthardware_pms/domain/repository/invoice_repository.dart';
import 'package:equatable/equatable.dart';

part 'invoice_list_event.dart';
part 'invoice_list_state.dart';

class InvoiceListBloc extends Bloc<InvoiceListEvent, InvoiceListState> {
  InvoiceListBloc(
    this._repository,
    this._productRepository,
    InvoiceListState initialState,
  ) : super(initialState) {
    on<FetchAllInvoicesEvent>(_onFetchInvoices);
    on<AddInvoiceEvent>(_onAddInvoice);
    on<UpdateInvoiceEvent>(_onUpdateInvoice);
    on<DeleteInvoiceEvent>(_onDeleteInvoice);
    on<FetchInvoiceProductsEvent>(_onFetchInvoiceProducts);
    on<AddInvoiceProductEvent>(_onAddInvoiceProduct);
    on<UpdateInvoiceProductEvent>(_onUpdateInvoiceProduct);
  }
  final InvoiceRepository _repository;
  final InvoiceProductRepository _productRepository;

  Future<void> _onFetchInvoices(FetchAllInvoicesEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final invoices = await _repository.getAllInvoices();
      emit(state.copyWith(invoices: invoices, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAddInvoice(AddInvoiceEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final invoice = await _repository.insertInvoice(event.invoice);
      final invoices = List<Invoice>.from(state.invoices)..add(invoice);
      emit(state.copyWith(invoices: invoices, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onUpdateInvoice(UpdateInvoiceEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _repository.updateInvoice(event.invoice);
      final invoices = List<Invoice>.from(state.invoices)
        ..removeWhere((i) => i.id == event.invoice.id)
        ..add(event.invoice);
      emit(state.copyWith(invoices: invoices, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onDeleteInvoice(DeleteInvoiceEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _repository.deleteInvoice(event.invoice);
      final invoices = List<Invoice>.from(state.invoices)..remove(event.invoice);
      emit(state.copyWith(invoices: invoices, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onFetchInvoiceProducts(
    FetchInvoiceProductsEvent event,
    Emitter<InvoiceListState> emit,
  ) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final products = await _productRepository.fetchInvoiceProductByInvoice(event.invoiceId);
      emit(state.copyWith(invoiceProducts: products, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAddInvoiceProduct(
    AddInvoiceProductEvent event,
    Emitter<InvoiceListState> emit,
  ) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final product = await _productRepository.insertInvoiceProduct(event.product);
      final products = List<InvoiceProduct>.from(state.invoiceProducts)..add(product);
      emit(state.copyWith(invoiceProducts: products, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onUpdateInvoiceProduct(
    UpdateInvoiceProductEvent event,
    Emitter<InvoiceListState> emit,
  ) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _productRepository.updateInvoiceProduct(event.product);
      final products = List<InvoiceProduct>.from(state.invoiceProducts)
        ..removeWhere((p) => p.id == event.product.id)
        ..add(event.product);
      emit(state.copyWith(invoiceProducts: products, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onDeleteInvoiceProduct(
    DeleteInvoiceProductEvent event,
    Emitter<InvoiceListState> emit,
  ) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      await _productRepository.deleteInvoiceProduct(event.productId);
      final products = List<InvoiceProduct>.from(state.invoiceProducts)
        ..removeWhere((p) => p.id == event.productId);
      emit(state.copyWith(invoiceProducts: products, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }
}
