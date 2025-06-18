import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/ui/kpi_card.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

class TotalSalesCard extends StatelessWidget {
  const TotalSalesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final totalSales = context.select(
      (InvoiceListBloc b) => b.state.invoices //
          .fold(0.0, (p, i) => p + (i.amountPaid ?? i.amountDue)),
    );
    final totalSalesFormatted = CurrencyFormatter.full(totalSales);

    return KPICard(
      'Total Sales',
      value: totalSalesFormatted,
      icon: const Icon(FluentIcons.product_warning),
    );
  }
}
