import 'dart:async';

import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/sales/sales_report/sales_report_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_generation.dart';
import 'package:easthardware_pms/presentation/views/reports/sales_report/'
    'extensions/sales_by_category_datum.dart';
import 'package:easthardware_pms/presentation/views/reports/sales_report/sales_query_data.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/bordered_date_picker.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/num_iterable_extension.dart';
import 'package:easthardware_pms/utils/number_string.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

typedef SalesByCategoryFunction = String Function(SalesByCategoryDatum);
typedef TotalSalesByCategoryFunction = String Function(List<SalesByCategoryDatum>);
typedef _SalesColumnRecord = (
  String name,
  int flex,
  pw.TableColumnWidth width,
  SalesByCategoryFunction value,
  TotalSalesByCategoryFunction? total,
);

extension type const _SalesColumn._(_SalesColumnRecord record) {
  const _SalesColumn({
    required String name,
    int flex = 1,
    required pw.TableColumnWidth width,
    required SalesByCategoryFunction value,
    TotalSalesByCategoryFunction? total,
  }) : this._((name, flex, width, value, total));

  String get name => record.$1;
  int get flex => record.$2;
  pw.TableColumnWidth get width => record.$3;
  SalesByCategoryFunction get value => record.$4;
  TotalSalesByCategoryFunction? get total => record.$5;
}

final salesColumns = <_SalesColumn>[
  _SalesColumn(
    name: 'Category Name',
    flex: 2,
    width: const pw.FlexColumnWidth(2),
    value: (args) => args.category.name,
    total: (args) => 'Total',
  ),
  _SalesColumn(
    name: 'Units Sold',
    width: const pw.FlexColumnWidth(1),
    value: (args) => args.unitsSold.toNumberString(),
    total: (data) => data.map((e) => e.unitsSold).sum().toNumberString(),
  ),
  _SalesColumn(
    name: 'Units Ordered',
    width: const pw.FlexColumnWidth(1),
    value: (args) => args.unitsOrdered.toNumberString(),
    total: (data) => data.map((e) => e.unitsOrdered).sum().toNumberString(),
  ),
  _SalesColumn(
    name: 'Selling Price',
    width: const pw.FlexColumnWidth(1),
    value: (args) => CurrencyFormatter.full(args.salePrice, "Php "),
    total: (data) => CurrencyFormatter.full(data.map((e) => e.salePrice).sum(), "Php "),
  ),
  _SalesColumn(
    name: 'Order Cost',
    width: const pw.FlexColumnWidth(1),
    value: (args) => CurrencyFormatter.full(args.orderCost, "Php "),
    total: (data) => CurrencyFormatter.full(data.map((e) => e.orderCost).sum(), "Php "),
  ),
  _SalesColumn(
    name: 'Total Revenue',
    width: const pw.FlexColumnWidth(1),
    value: (args) => CurrencyFormatter.full(args.totalRevenue, "Php "),
    total: (data) => CurrencyFormatter.full(data.map((e) => e.totalRevenue).sum(), "Php "),
  ),
  _SalesColumn(
    name: 'Total Order Cost',
    width: const pw.FlexColumnWidth(1),
    value: (args) => CurrencyFormatter.full(args.totalCost, "Php "),
    total: (data) => CurrencyFormatter.full(data.map((e) => e.totalCost).sum(), "Php "),
  ),
  _SalesColumn(
    name: 'Gross Profit',
    width: const pw.FlexColumnWidth(1),
    value: (args) => CurrencyFormatter.full(args.grossProfit, "Php "),
    total: (data) => CurrencyFormatter.full(data.map((e) => e.grossProfit).sum(), "Php "),
  ),
];

class SalesByCategoryPage extends StatelessWidget {
  const SalesByCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesReportBloc(
        context.read<ProductListBloc>().state.allProducts,
        context.read<InvoiceListBloc>().state.invoices,
        context.read<InvoiceListBloc>().state.invoiceProducts,
        context.read<OrderListBloc>().state.allOrders,
        context.read<OrderListBloc>().state.allOrderProducts,
        context
            .read<ProductListBloc>()
            .state
            .allProducts

            /// FIXME: What is this.
            .map((p) => Category(name: p.categoryName ?? 'Uncategorized', id: p.categoryId))
            .toList(),
      ),
      child: Builder(builder: (context) {
        return MultiBlocListener(
          listeners: [
            BlocListener<ProductListBloc, ProductListState>(
              listenWhen: (p, c) => p.allProducts != c.allProducts,
              listener: (context, state) {
                context
                    .read<SalesReportBloc>()
                    .add(SalesReportUpdateProductsEvent(state.allProducts));
              },
            ),
            BlocListener<InvoiceListBloc, InvoiceListState>(
              listenWhen: (p, c) => p.invoiceProducts != c.invoiceProducts,
              listener: (context, state) {
                context
                    .read<SalesReportBloc>()
                    .add(SalesReportUpdateInvoiceProductsEvent(state.invoiceProducts));
              },
            ),
            BlocListener<OrderListBloc, OrderListState>(
              listenWhen: (p, c) => p.allOrderProducts != c.allOrderProducts,
              listener: (context, state) {
                context
                    .read<SalesReportBloc>()
                    .add(SalesReportUpdateOrderProductsEvent(state.allOrderProducts));
              },
            ),
          ],
          child: const Padding(
            padding: AppPadding.panePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SalesReportHeader(),
                Spacing.v16,
                Expanded(
                  child: AnimatedSingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SalesReportOptions(),
                        Spacing.v24,
                        SalesReportPreview(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class SalesReportHeader extends StatelessWidget {
  const SalesReportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => context.navigate(AppRoutes.admin.reports),
        ),
        Spacing.h16,
        const DisplayText('Sales Report'),
      ],
    );
  }
}

class SalesReportOptions extends StatelessWidget {
  const SalesReportOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SubheadingText('Report Options'),
        Spacing.v12,
        Container(
          padding: AppPadding.cardPadding,
          color: FluentTheme.of(context).cardColor,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    _StartDateSelection(),
                    _EndDateSelection(),
                    _SortBySelection(),
                    _RowLimitSelection(),
                  ].withSpacing(() => Spacing.v8),
                ),
              ),
              const _GenerateButtons(),
            ],
          ),
        ),
      ],
    );
  }
}

class _StartDateSelection extends StatelessWidget {
  const _StartDateSelection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 80, child: Text('Start Date: ')),
        Spacing.h8,
        BorderedDatePicker(
          selected: context.select((SalesReportBloc b) => b.state.queryData.startDate),
          onChanged: (value) => context //
              /// For the start date, we want it to be inclusive.
              .read<SalesReportBloc>()
              .add(SalesReportSetStartDateEvent(value)),
        ),
      ],
    );
  }
}

class _EndDateSelection extends StatelessWidget {
  const _EndDateSelection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 80, child: Text('End Date: ')),
        Spacing.h8,
        BorderedDatePicker(
          selected: context.select((SalesReportBloc b) => b.state.queryData.endDate),
          onChanged: (value) =>
              context.read<SalesReportBloc>().add(SalesReportSetEndDateEvent(value)),
        ),
      ],
    );
  }
}

class _SortBySelection extends StatelessWidget {
  const _SortBySelection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 80, child: Text('Sort By: ')),
        Spacing.h8,
        ComboBox(
          value: context.select((SalesReportBloc b) => b.state.queryData.categorySortBy),
          onChanged: (value) {
            if (value != null) {
              context //
                  .read<SalesReportBloc>()
                  .add(SalesReportSetCategoryReportSortByEvent(value));
            }
          },
          items: [
            for (final sortBy in SalesByCategoryReportSortBy.values)
              ComboBoxItem(
                value: sortBy,
                child: Text(sortBy.name),
              ),
          ],
        )
      ],
    );
  }
}

class _RowLimitSelection extends StatelessWidget {
  const _RowLimitSelection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 80, child: Text('Row Limit: ')),
        Spacing.h8,
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 120,
            maxWidth: 180,
          ),
          child: NumberBox<int>(
            value: context.select((SalesReportBloc b) => b.state.queryData.rowLimit),
            min: 1,
            mode: SpinButtonPlacementMode.none,
            clearButton: false,
            onChanged: (value) {
              if (value != null) {
                context
                    .read<SalesReportBloc>() //
                    .add(SalesReportSetRowLimitEvent(value));
              }
            },
          ),
        ),
      ],
    );
  }
}

class _GenerateButtons extends StatelessWidget {
  const _GenerateButtons();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesReportBloc, SalesReportState>(
      builder: (context, reportState) {
        final salesData = reportState.queryData.salesByCategoryDataWithTake ?? [];

        return Row(
          children: [
            TextButtonFilled(
              'Generate Sales Report',
              onPressed: reportState.isGenerating
                  ? null
                  : () => unawaited(_previewReport(context, reportState, salesData)),
            ),
          ],
        );
      },
    );
  }
}

class SalesReportPreview extends StatelessWidget {
  const SalesReportPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubheadingText('Report Preview'),
        Spacing.v12,
        _SalesTablePreview(),
      ],
    );
  }
}

class _SalesTablePreview extends StatelessWidget {
  const _SalesTablePreview();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SalesReportBloc, SalesReportState, List<SalesByCategoryDatum>?>(
      selector: (state) => state.queryData.salesByCategoryDataWithTake,
      builder: (context, salesData) {
        final data = salesData ?? [];

        return Container(
          padding: AppPadding.cardPadding,
          color: FluentTheme.of(context).cardColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Row(
                  children: [
                    for (final _SalesColumn(:name, :flex) in salesColumns)
                      Expanded(flex: flex, child: BodyText(name, fontWeight: FontWeight.w600)),
                  ].withSpacing(() => Spacing.h4),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final (product, extras) = data[index];

                  return Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: FluentTheme.of(context).menuColor,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (final _SalesColumn(:flex, :value) in salesColumns)
                          Expanded(
                            flex: flex,
                            child: Text(
                              value((product, extras)),
                              style: TextStyles.body,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ].withSpacing(() => Spacing.h4),
                    ),
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: FluentTheme.of(context).menuColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: ([
                    for (final _SalesColumn(:flex, :total) in salesColumns)
                      if (total != null)
                        Expanded(
                          flex: flex,
                          child: Text(
                            total(data),
                            style: TextStyles.body.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        Expanded(
                          flex: flex,
                          child: const Text(
                            '',
                            style: TextStyles.body,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ]).withSpacing(() => Spacing.h4),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

// Static methods for PDF operations
Future<void> _previewReport(
  BuildContext context,
  SalesReportState reportState,
  List<SalesByCategoryDatum> salesData,
) async {
  context.read<SalesReportBloc>().add(const SalesReportSetGeneratingEvent(true));

  try {
    /// Create the PDF overlay.
    showPdfOverlay(builder: (_, overlayEntry) {
      return MultiProvider(
        providers: [
          BlocProvider.value(value: context.read<SalesReportBloc>()),
          BlocProvider.value(value: context.read<ProductListBloc>()),
          BlocProvider.value(value: context.read<InvoiceListBloc>()),
          BlocProvider.value(value: context.read<OrderListBloc>()),
        ],
        child: PdfOverlay(
          overlayEntry: overlayEntry,
          generatorCreator: () => _SalesReportPdfGenerator(
            salesData: salesData,
            startDate: reportState.queryData.startDate,
            endDate: reportState.queryData.endDate,
          ),
        ),
      );
    });
  } catch (e, st) {
    if (context.mounted) {
      showNotification.error(title: 'Error', message: 'Failed to generate report: $e');
      printBoxed('$e\n$st', 'PDF Generation');
    }
  } finally {
    if (context.mounted) {
      context.read<SalesReportBloc>().add(const SalesReportSetGeneratingEvent(false));
    }
  }
}

const _cellPadding = pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0);

// PDF generation methods
final class _SalesReportPdfGenerator implements PdfGenerator {
  const _SalesReportPdfGenerator({
    required this.salesData,
    required this.startDate,
    required this.endDate,
  });

  final List<SalesByCategoryDatum> salesData;
  final DateTime startDate;
  final DateTime endDate;

  @override
  String get fileName =>
      'Sales_Report_${startDate.toIso8601String().split('T').first}_to_${endDate.toIso8601String().split('T').first}.pdf';

  @override
  Future<Uint8List> generatePdf(PdfPageFormat? format) async {
    final pdf = pw.Document();
    final logo = await rootBundle.load('assets/icons/logo.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildPdfHeader(context, logo, startDate, endDate),
        build: (context) {
          return [
            // Sales Table
            pw.Table(
              border: pw.TableBorder.symmetric(),
              columnWidths: {
                for (final (index, _SalesColumn(:width)) in salesColumns.indexed) index: width,
              },
              children: [
                // Table Header
                _buildPdfSalesHeader(),

                // Table Rows
                for (final salesDatum in salesData) _buildPdfSalesItem(salesDatum),

                _buildBottomRow(salesData),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfHeader(
    pw.Context context,
    ByteData logo,
    DateTime startDate,
    DateTime endDate,
  ) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Image(
                      pw.MemoryImage(logo.buffer.asUint8List()),
                      width: 18,
                      height: 18,
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'East Hardware',
                      style: const pw.TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                pw.Text(
                  'Sales Report',
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Period: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 15),
      ],
    );
  }

  pw.TableRow _buildPdfSalesHeader() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      children: [
        for (final _SalesColumn(:name) in salesColumns)
          pw.Padding(
            padding: _cellPadding,
            child: pw.Text(
              name,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ),
      ],
    );
  }

  pw.TableRow _buildPdfSalesItem(SalesByCategoryDatum salesDatum) {
    return pw.TableRow(
      children: [
        for (final _SalesColumn(:value) in salesColumns)
          pw.Padding(
            padding: _cellPadding,
            child: pw.Text(
              value(salesDatum),
              style: const pw.TextStyle(fontSize: 8),
              softWrap: false,
              overflow: pw.TextOverflow.span,
            ),
          ),
      ],
    );
  }

  pw.TableRow _buildBottomRow(List<SalesByCategoryDatum> salesData) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      children: [
        for (final _SalesColumn(:total) in salesColumns)
          if (total != null)
            pw.Padding(
              padding: _cellPadding,
              child: pw.Text(
                total(salesData),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              ),
            )
          else
            pw.Padding(
              padding: _cellPadding,
              child: pw.Text(
                '',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
      ],
    );
  }
}
