import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/business_snapshot/business_snapshot_report_bloc.dart';
import 'package:easthardware_pms/presentation/views/reports/business_snapshot/business_snapshot_report.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BusinessSnapshotReportProvider extends StatelessWidget {
  const BusinessSnapshotReportProvider({
    super.key,
    required this.products,
    required this.invoices,
    required this.invoiceProducts,
    required this.orders,
    required this.orderProducts,
    required this.expenseTypes,
  });

  final List<Product> products;
  final List<Invoice> invoices;
  final List<InvoiceProduct> invoiceProducts;
  final List<Order> orders;
  final List<OrderProduct> orderProducts;
  final List<ExpenseType> expenseTypes;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BusinessSnapshotReportBloc(
        products,
        invoices,
        invoiceProducts,
        orders,
        orderProducts,
        expenseTypes,
      ),
      child: const BusinessSnapshotReport(),
    );
  }
}
