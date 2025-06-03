part of 'invoice_list_bloc.dart';

class InvoiceListState extends Equatable {
  final List<Invoice> allInvoices;
  final List<Invoice>? filteredInvoices;
  final List<Invoice> paidInvoices;
  final List<Invoice> unpaidInvoices;
  final DataStatus status;

  const InvoiceListState({
    this.allInvoices = const [],
    this.filteredInvoices,
    this.paidInvoices = const [],
    this.unpaidInvoices = const [],
    this.status = DataStatus.initial,
  });

  InvoiceListState copyWith({
    List<Invoice>? allInvoices,
    List<Invoice>? filteredInvoices,
    List<Invoice>? paidInvoices,
    List<Invoice>? unpaidInvoices,
    DataStatus? status,
  }) {
    return InvoiceListState(
      allInvoices: allInvoices ?? this.allInvoices,
      filteredInvoices: filteredInvoices ?? this.filteredInvoices,
      paidInvoices: paidInvoices ?? this.paidInvoices,
      unpaidInvoices: unpaidInvoices ?? this.unpaidInvoices,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [
        allInvoices,
        filteredInvoices ?? [],
        paidInvoices,
        unpaidInvoices,
        status,
      ];
}
