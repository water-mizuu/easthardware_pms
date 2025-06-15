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

      final products = event.products
          .map(
            (product) => _productRepository.insertInvoiceProduct(
              product.copyWith(invoiceId: invoice.id!),
            ),
          )
          .toList();
      final resolvedProducts = await Future.wait(products);
      final invoices = List<Invoice>.from(state.invoices)..add(invoice);
      emit(
        state.copyWith(
          invoices: invoices,
          invoiceProducts: resolvedProducts,
          status: DataStatus.success,
        ),
      );
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
}
