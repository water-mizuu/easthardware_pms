import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/repository/invoice_product_repository.dart';
import 'package:easthardware_pms/domain/repository/invoice_repository.dart';
import 'package:easthardware_pms/domain/repository/product_repository.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';

part 'invoice_list_event.dart';
part 'invoice_list_state.dart';

class InvoiceListBloc extends Bloc<InvoiceListEvent, InvoiceListState> {
  InvoiceListBloc(
    this._repository,
    this._itemRepository,
    this._productRepository,
    InvoiceListState initialState,
  ) : super(initialState) {
    on<FetchAllInvoicesEvent>(_onFetchInvoices);
    on<AddInvoiceEvent>(_onAddInvoice);
    on<UpdateInvoiceEvent>(_onUpdateInvoice);
    on<DeleteInvoiceEvent>(_onDeleteInvoice);
    on<FetchInvoiceProductsEvent>(_onFetchInvoiceProducts);
    on<EditInvoiceEvent>(_onEditInvoice);
  }
  final InvoiceRepository _repository;
  final InvoiceProductRepository _itemRepository;
  final ProductRepository _productRepository;

  Future<void> _onFetchInvoices(FetchAllInvoicesEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final invoices = await _repository.getAllInvoices();
      final invoiceProducts = await _itemRepository.fetchAllInvoiceProducts();
      emit(
        state.copyWith(
          invoices: invoices,
          invoiceProducts: invoiceProducts,
          status: DataStatus.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onAddInvoice(AddInvoiceEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      // 1. Insert the invoice
      final invoice = await _repository.insertInvoice(event.invoice);

      // 2. Insert the invoice products
      final products = event.invoiceProducts
          .map(
            (product) => _itemRepository.insertInvoiceProduct(
              product.copyWith(invoiceId: invoice.id!),
            ),
          )
          .toList();

      // 3. Update the product stock
      for (final invoiceProduct in event.invoiceProducts) {
        await _productRepository.updateProductStock(
          invoiceProduct.productId,
          -invoiceProduct.quantity * (invoiceProduct.conversionFactor ?? 1.0),
        );
      }

      // 4. Resolve the products
      final resolvedProducts = await Future.wait(products);
      final invoices = List<Invoice>.from(state.invoices)..add(invoice);
      emit(
        state.copyWith(
          invoices: invoices,
          latest: invoice,
          invoiceProducts: resolvedProducts,
          status: DataStatus.success,
        ),
      );
    } catch (e, stackTrace) {
      printBoxed('Error adding invoice: $e \n $stackTrace', 'InvoiceListBloc');
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onEditInvoice(EditInvoiceEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      // 1. Fetch original invoice products
      final originalInvoiceProducts =
          await _itemRepository.fetchInvoiceProductsByInvoice(event.invoice.id!);

      // 2. Reverse the stock for original products (add back)
      final reverseOriginalStockFutures = originalInvoiceProducts.map((product) {
        return _productRepository.updateProductStock(
          product.productId,
          product.quantity * (product.conversionFactor ?? 1.0),
        );
      }).toList();
      await Future.wait(reverseOriginalStockFutures);

      // 3. Update the invoice
      final updatedInvoice = await _repository.updateInvoice(event.invoice);

      // 4. Delete existing invoice products
      await _itemRepository.deleteInvoiceProductsByInvoiceId(event.invoice.id!);

      // 5. Insert the new invoice products
      final products = event.invoiceProducts
          .map((product) => _itemRepository.insertInvoiceProduct(
                product.copyWith(invoiceId: event.invoice.id!),
              ))
          .toList();
      await Future.wait(products);

      // 6. Update the product stock for new products (subtract, like add invoice)
      for (final invoiceProduct in event.invoiceProducts) {
        await _productRepository.updateProductStock(
          invoiceProduct.productId,
          -invoiceProduct.quantity * (invoiceProduct.conversionFactor ?? 1.0),
        );
      }

      // 7. Update the orders list in the state and fetch latest invoice products
      final invoices =
          state.invoices.map((i) => i.id == event.invoice.id ? event.invoice : i).toList();
      final latestInvoiceProducts =
          await _itemRepository.fetchInvoiceProductsByInvoice(event.invoice.id!);

      // Create a merged list of invoice products that:
      // 1. Keeps all products NOT associated with the edited invoice
      // 2. Adds the updated products for the edited invoice
      final updatedInvoiceProducts = [
        ...state.invoiceProducts.where((product) => product.invoiceId != event.invoice.id!),
        ...latestInvoiceProducts,
      ];

      emit(state.copyWith(
        invoices: invoices,
        latest: updatedInvoice,
        invoiceProducts: updatedInvoiceProducts,
        status: DataStatus.success,
      ));
    } catch (e, stackTrace) {
      printBoxed('Error editing invoice: $e \n $stackTrace', 'InvoiceListBloc');
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  Future<void> _onUpdateInvoice(UpdateInvoiceEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final invoice = await _repository.updateInvoice(event.invoice);
      final invoices = List<Invoice>.from(state.invoices)
        ..removeWhere((i) => i.id == event.invoice.id)
        ..add(event.invoice);
      emit(state.copyWith(
        invoices: invoices,
        latest: invoice,
        status: DataStatus.success,
      ));
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

  Future<void> _onFetchInvoiceProducts(FetchInvoiceProductsEvent event, Emitter emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final products = await _itemRepository.fetchInvoiceProductsByInvoice(event.invoiceId);
      printBoxed('Fetched invoice products: ${products.length}', 'InvoiceListBloc');
      emit(state.copyWith(invoiceProducts: products, status: DataStatus.success));
    } catch (e) {
      emit(state.copyWith(status: DataStatus.error));
    }
  }
}
