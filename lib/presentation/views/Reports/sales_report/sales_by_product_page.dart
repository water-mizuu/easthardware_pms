import 'dart:async';

import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/sales/sales_report/sales_report_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_generation.dart';
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

/// Type definition for a sales column record
/// Contains the column name, flex, width, value formatter, and optional total calculator
typedef _SalesColumnRecord = (
  String name,
  int flex,
  pw.TableColumnWidth width,
  String Function((Product, SalesExtras)) value,
  String Function(List<(Product, SalesExtras)>)? total,
);

/// Extension type to make working with sales columns easier
extension type const _SalesColumn._(_SalesColumnRecord record) {
  /// Creates a sales column with the specified properties
  const _SalesColumn({
    required String name,
    required pw.TableColumnWidth width,
    required String Function((Product, SalesExtras)) value,
    String Function(List<(Product, SalesExtras)>)? total,
    int flex = 1,
  }) : this._((name, flex, width, value, total));

  /// The display name of the column
  String get name => record.$1;

  /// The flex value for layout purposes
  int get flex => record.$2;

  /// The PDF table column width
  pw.TableColumnWidth get width => record.$3;

  /// Function to format the value for a single row
  String Function((Product, SalesExtras)) get value => record.$4;

  /// Optional function to calculate the total for this column
  String Function(List<(Product, SalesExtras)>)? get total => record.$5;
}

// SalesExtrasPair extension is now defined in sales_query_data.dart

/// Column definitions for the sales report table
/// Each column includes:
/// - Display name
/// - Layout configuration (flex, width)
/// - Value formatting function
/// - Optional total calculation function
final salesColumns = <_SalesColumn>[
  _SalesColumn(
    name: 'SKU',
    width: const pw.FlexColumnWidth(1),
    value: (datum) => datum.product.sku,
    total: (_) => 'Total',
  ),
  _SalesColumn(
    name: 'Product Name',
    flex: 2,
    width: const pw.FlexColumnWidth(2),
    value: (datum) => datum.product.name,
  ),
  _SalesColumn(
    name: 'Units Sold',
    width: const pw.FlexColumnWidth(1),
    value: (datum) => datum.extras.unitsSold.toNumberString(),
    total: (data) => data.map((e) => e.$2.unitsSold).sum().toNumberString(),
  ),
  _SalesColumn(
    name: 'Units Ordered',
    width: const pw.FlexColumnWidth(1),
    value: (datum) => datum.extras.unitsOrdered.toNumberString(),
    total: (data) => data.map((e) => e.$2.unitsOrdered).sum().toNumberString(),
  ),
  _SalesColumn(
    name: 'Selling Price',
    width: const pw.FlexColumnWidth(1),
    value: (datum) => CurrencyFormatter.full(datum.salePrice, "Php "),
    total: (data) => CurrencyFormatter.full(data.map((e) => e.salePrice).sum(), "Php "),
  ),
  _SalesColumn(
    name: 'Order Cost',
    width: const pw.FlexColumnWidth(1),
    value: (datum) => CurrencyFormatter.full(datum.orderCost, "Php "),
    total: (data) => CurrencyFormatter.full(data.map((e) => e.orderCost).sum(), "Php "),
  ),
  _SalesColumn(
    name: 'Total Revenue',
    width: const pw.FlexColumnWidth(1),
    value: (datum) => CurrencyFormatter.full(datum.totalRevenue, "Php "),
    total: (data) => CurrencyFormatter.full(data.map((e) => e.totalRevenue).sum(), "Php "),
  ),
  _SalesColumn(
    name: 'Total Order Cost',
    width: const pw.FlexColumnWidth(1),
    value: (datum) => CurrencyFormatter.full(datum.orderCost, "Php "),
    total: (data) => CurrencyFormatter.full(data.map((e) => e.orderCost).sum(), "Php "),
  ),
  _SalesColumn(
    name: 'Gross Profit',
    width: const pw.FlexColumnWidth(1),
    value: (datum) => CurrencyFormatter.full(datum.grossProfit, "Php "),
    total: (data) => CurrencyFormatter.full(data.map((e) => e.totalRevenue).sum(), "Php "),
  ),
];

/// A page that displays sales data organized by product
///
/// This page shows a table of products with their sales metrics including:
/// - Units sold and ordered
/// - Revenue and cost figures
/// - Profit calculations
///
/// The data can be filtered by date range and sorted in various ways
class SalesByProductPage extends StatelessWidget {
  const SalesByProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesReportBloc(
        context.read<ProductListBloc>().state.allProducts,
        context.read<InvoiceListBloc>().state.invoices,
        context.read<InvoiceListBloc>().state.invoiceProducts,
        context.read<OrderListBloc>().state.allOrders,
        context.read<OrderListBloc>().state.allOrderProducts,
        (context.read<ProductListBloc>().state.allProducts)
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

/// The header section of the sales report page
///
/// Includes the page title and navigation controls
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

/// The options section of the sales report page
///
/// Contains controls for:
/// - Date range selection
/// - Sorting options
/// - Report generation controls
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
                  ].withSpacing(() => Spacing.v16),
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
        const Text('Start Date: '),
        Spacing.h8,
        BorderedDatePicker(
          selected: context.select((SalesReportBloc b) => b.state.queryData.startDate),
          onChanged: (value) =>
              context.read<SalesReportBloc>().add(SalesReportSetStartDateEvent(value)),
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
        const Text('End Date: '),
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
    return BlocSelector<SalesReportBloc, SalesReportState, SalesQueryData>(
      selector: (state) => state.queryData,
      builder: (context, queryData) {
        return Row(
          children: [
            const Text('Sort By: '),
            Spacing.h8,
            ComboBox(
              value: context.select((SalesReportBloc bloc) => bloc.state.queryData.productSortBy),
              onChanged: (value) {
                if (value != null) {
                  context
                      .read<SalesReportBloc>()
                      .add(SalesReportSetProductReportSortByEvent(value));
                }
              },
              items: [
                for (final sortBy in SalesByProductReportSortBy.values)
                  ComboBoxItem(
                    value: sortBy,
                    child: Text(sortBy.name),
                  ),
              ],
            )
          ],
        );
      },
    );
  }
}

class _GenerateButtons extends StatelessWidget {
  const _GenerateButtons();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesReportBloc, SalesReportState>(
      builder: (context, reportState) {
        final salesData = reportState.queryData.salesByProductData ?? [];

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

/// The preview section of the sales report page
///
/// Displays a table with the sales data according to the selected options
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
    return BlocSelector<SalesReportBloc, SalesReportState, List<(Product, SalesExtras)>?>(
      selector: (state) => state.queryData.salesByProductData,
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
                              value(data[index]),
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

/// Generates and displays a PDF preview of the sales report
///
/// This function creates a PDF overlay with the sales report data,
/// allowing the user to preview, print, or save the report.
///
/// @param context The BuildContext
/// @param reportState The current state of the SalesReportBloc
/// @param salesData The sales data to display in the report
Future<void> _previewReport(
  BuildContext context,
  SalesReportState reportState,
  List<(Product, SalesExtras)> salesData,
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

/// Standard cell padding used in PDF tables
const _cellPadding = pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0);

/// PDF generator for sales reports
///
/// Handles the creation of a PDF document containing:
/// - Report header with company information and date range
/// - Sales data table with product details
/// - Totals row with aggregate calculations
final class _SalesReportPdfGenerator implements PdfGenerator {
  const _SalesReportPdfGenerator({
    required this.salesData,
    required this.startDate,
    required this.endDate,
  });

  final List<(Product, SalesExtras)> salesData;
  final DateTime startDate;
  final DateTime endDate;

  @override
  String get fileName =>
      'Sales_Report_${startDate.toIso8601String().split('T').first}_to_${endDate.toIso8601String().split('T').first}.pdf';

  @override
  Future<Uint8List> generatePdf(PdfPageFormat? format) async {
    final pdf = pw.Document();
    final logo = await rootBundle.load('assets/icons/app.png');

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
                for (final pair in salesData) _buildPdfSalesItem(pair),

                _buildBottomRow(),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Builds the PDF header with company logo and report information
  ///
  /// @param context The PDF context
  /// @param logo The company logo as ByteData
  /// @param startDate The report start date
  /// @param endDate The report end date
  /// @return A widget representing the PDF header
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

  /// Builds the header row for the sales table
  ///
  /// @return A table row with column headers
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

  /// Builds a data row for the sales table
  ///
  /// @param product The product data
  /// @param extras The sales extras data
  /// @return A table row with product sales data
  pw.TableRow _buildPdfSalesItem((Product, SalesExtras) pair) {
    return pw.TableRow(
      children: [
        for (final _SalesColumn(:value) in salesColumns)
          pw.Padding(
            padding: _cellPadding,
            child: pw.Text(
              value(pair),
              style: const pw.TextStyle(fontSize: 8),
              softWrap: false,
              overflow: pw.TextOverflow.span,
            ),
          ),
      ],
    );
  }

  /// Builds the totals row for the sales table
  ///
  /// @return A table row with column totals
  pw.TableRow _buildBottomRow() {
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
            )
      ],
    );
  }
}
