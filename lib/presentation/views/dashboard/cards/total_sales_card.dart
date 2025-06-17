import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TotalSalesCard extends StatelessWidget {
  const TotalSalesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: 'Php ', decimalDigits: 2);
    final totalSales = context.select(
      (InvoiceListBloc b) => b.state.invoices.fold<double>(
        0.0,
        (previousValue, invoice) => previousValue + (invoice.amountPaid ?? invoice.amountDue),
      ),
    );
    final totalSalesFormatted = formatter.format(totalSales);

    return KPICard(
      'Total Sales',
      value: totalSalesFormatted,
      icon: const Icon(FluentIcons.product_warning),
    );
  }
}
