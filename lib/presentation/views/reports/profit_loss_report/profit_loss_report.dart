import 'dart:async';

import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/profit_loss/profit_loss_report/profit_loss_report_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_generation.dart';
import 'package:easthardware_pms/presentation/views/reports/profit_loss_report/profit_loss_query_data.dart';
import 'package:easthardware_pms/presentation/widgets/animated_single_child_scroll_view.dart';
import 'package:easthardware_pms/presentation/widgets/bordered_date_picker.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/presentation/widgets/ui/styles.dart';
import 'package:easthardware_pms/presentation/widgets/ui/text_button.dart';
import 'package:easthardware_pms/utils/boxed.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

typedef ProfitLossValueFunction = String Function(ProfitLossEntry);
typedef TotalProfitLossFunction = String Function(List<ProfitLossEntry>);
typedef _ProfitLossColumnRecord = (
  String name,
  int flex,
  pw.TableColumnWidth width,
  ProfitLossValueFunction value,
  TotalProfitLossFunction? total,
);

extension type const _ProfitLossColumn._(_ProfitLossColumnRecord record) {
  const _ProfitLossColumn({
    required String name,
    int flex = 1,
    required pw.TableColumnWidth width,
    required ProfitLossValueFunction value,
    TotalProfitLossFunction? total,
  }) : this._((name, flex, width, value, total));

  String get name => record.$1;
  int get flex => record.$2;
  pw.TableColumnWidth get width => record.$3;
  ProfitLossValueFunction get value => record.$4;
  TotalProfitLossFunction? get total => record.$5;
}

final profitLossColumns = <_ProfitLossColumn>[
  _ProfitLossColumn(
    name: 'Period',
    flex: 2,
    width: const pw.FlexColumnWidth(2),
    value: (entry) {
      final formatter = DateFormat('MMM dd, yyyy');
      switch (entry.date.month) {
        case 1:
        case 2:
        case 3:
          return 'Q1 ${entry.date.year}';
        case 4:
        case 5:
        case 6:
          return 'Q2 ${entry.date.year}';
        case 7:
        case 8:
        case 9:
          return 'Q3 ${entry.date.year}';
        case 10:
        case 11:
        case 12:
          return 'Q4 ${entry.date.year}';
        default:
          return formatter.format(entry.date);
      }
    },
    total: (data) => 'Total',
  ),
  _ProfitLossColumn(
    name: 'Revenue',
    width: const pw.FlexColumnWidth(1),
    value: (entry) => CurrencyFormatter.full(entry.revenue, "Php "),
    total: (data) => CurrencyFormatter.full(
        data.map((e) => e.revenue).fold<double>(0, (prev, curr) => prev + curr), "Php "),
  ),
  _ProfitLossColumn(
    name: 'Expenses',
    width: const pw.FlexColumnWidth(1),
    value: (entry) => CurrencyFormatter.full(entry.expenses, "Php "),
    total: (data) => CurrencyFormatter.full(
        data.map((e) => e.expenses).fold<double>(0, (prev, curr) => prev + curr), "Php "),
  ),
  _ProfitLossColumn(
    name: 'Profit',
    width: const pw.FlexColumnWidth(1),
    value: (entry) => CurrencyFormatter.full(entry.profit, "Php "),
    total: (data) => CurrencyFormatter.full(
        data.map((e) => e.profit).fold<double>(0, (prev, curr) => prev + curr), "Php "),
  ),
  _ProfitLossColumn(
    name: 'Profit Margin',
    width: const pw.FlexColumnWidth(1),
    value: (entry) => "${entry.profitMargin.toStringAsFixed(2)}%",
    total: (data) {
      final totalRevenue = data.map((e) => e.revenue).fold<double>(0, (prev, curr) => prev + curr);
      final totalProfit = data.map((e) => e.profit).fold<double>(0, (prev, curr) => prev + curr);
      final margin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0;
      return "${margin.toStringAsFixed(2)}%";
    },
  ),
];

class ProfitLossReportPage extends StatelessWidget {
  const ProfitLossReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfitLossReportBloc(
        context.read<ProductListBloc>().state.allProducts,
        context.read<InvoiceListBloc>().state.invoices,
        context.read<InvoiceListBloc>().state.invoiceProducts,
        context.read<OrderListBloc>().state.allOrders,
        context.read<OrderListBloc>().state.allOrderProducts,
      ),
      child: Builder(builder: (context) {
        return MultiBlocListener(
          listeners: [
            BlocListener<ProductListBloc, ProductListState>(
              listenWhen: (p, c) => p.allProducts != c.allProducts,
              listener: (context, state) {
                context
                    .read<ProfitLossReportBloc>()
                    .add(ProfitLossReportUpdateProductsEvent(state.allProducts));
              },
            ),
            BlocListener<InvoiceListBloc, InvoiceListState>(
              listenWhen: (p, c) => p.invoices != c.invoices,
              listener: (context, state) {
                context
                    .read<ProfitLossReportBloc>()
                    .add(ProfitLossReportUpdateInvoicesEvent(state.invoices));
              },
            ),
            BlocListener<InvoiceListBloc, InvoiceListState>(
              listenWhen: (p, c) => p.invoiceProducts != c.invoiceProducts,
              listener: (context, state) {
                context
                    .read<ProfitLossReportBloc>()
                    .add(ProfitLossReportUpdateInvoiceProductsEvent(state.invoiceProducts));
              },
            ),
            BlocListener<OrderListBloc, OrderListState>(
              listenWhen: (p, c) => p.allOrders != c.allOrders,
              listener: (context, state) {
                context
                    .read<ProfitLossReportBloc>()
                    .add(ProfitLossReportUpdateOrdersEvent(state.allOrders));
              },
            ),
            BlocListener<OrderListBloc, OrderListState>(
              listenWhen: (p, c) => p.allOrderProducts != c.allOrderProducts,
              listener: (context, state) {
                context
                    .read<ProfitLossReportBloc>()
                    .add(ProfitLossReportUpdateOrderProductsEvent(state.allOrderProducts));
              },
            ),
          ],
          child: const Padding(
            padding: AppPadding.panePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfitLossReportHeader(),
                Spacing.v16,
                Expanded(
                  child: AnimatedSingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfitLossReportOptions(),
                        Spacing.v24,
                        ProfitLossSummaryCard(),
                        Spacing.v24,
                        ProfitLossReportPreview(),
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

class ProfitLossReportHeader extends StatelessWidget {
  const ProfitLossReportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => context.navigate(AppRoutes.admin.reports),
        ),
        Spacing.h16,
        const DisplayText('Profit and Loss Report'),
      ],
    );
  }
}

class ProfitLossReportOptions extends StatelessWidget {
  const ProfitLossReportOptions({super.key});

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
                    _GroupBySelection(),
                    _SortBySelection(),
                    _TakeSelection(),
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

class ProfitLossSummaryCard extends StatelessWidget {
  const ProfitLossSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProfitLossReportBloc, ProfitLossReportState, ProfitLossSummary?>(
      selector: (state) => state.queryData.summary,
      builder: (context, summary) {
        if (summary == null) {
          return const SizedBox();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SubheadingText('Summary'),
            Spacing.v12,
            Container(
              padding: AppPadding.cardPadding,
              color: FluentTheme.of(context).cardColor,
              child: Row(
                children: [
                  _SummaryCard(
                    title: 'Total Revenue',
                    value: CurrencyFormatter.full(summary.totalRevenue, "Php "),
                    color: Colors.green,
                  ),
                  Spacing.h16,
                  _SummaryCard(
                    title: 'Total Expenses',
                    value: CurrencyFormatter.full(summary.totalExpenses, "Php "),
                    color: Colors.red,
                  ),
                  Spacing.h16,
                  _SummaryCard(
                    title: 'Net Profit',
                    value: CurrencyFormatter.full(summary.totalProfit, "Php "),
                    color: summary.totalProfit >= 0 ? Colors.green : Colors.red,
                  ),
                  Spacing.h16,
                  _SummaryCard(
                    title: 'Profit Margin',
                    value: "${summary.averageProfitMargin.toStringAsFixed(2)}%",
                    color: summary.averageProfitMargin >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: color.withOpacity(0.3), width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: FluentTheme.of(context).typography.bodyStrong,
              textAlign: TextAlign.center,
            ),
            Spacing.v8,
            Text(
              value,
              style: FluentTheme.of(context).typography.title,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
          selected: context.select((ProfitLossReportBloc b) => b.state.queryData.startDate),
          onChanged: (value) => context //
              .read<ProfitLossReportBloc>()
              .add(ProfitLossReportSetStartDateEvent(value)),
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
          selected: context.select((ProfitLossReportBloc b) => b.state.queryData.endDate),
          onChanged: (value) => context //
              .read<ProfitLossReportBloc>()
              .add(ProfitLossReportSetEndDateEvent(value)),
        ),
      ],
    );
  }
}

class _GroupBySelection extends StatelessWidget {
  const _GroupBySelection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Group By: '),
        Spacing.h8,
        ComboBox(
          value: context.select((ProfitLossReportBloc b) => b.state.queryData.groupBy),
          onChanged: (value) {
            if (value != null) {
              context //
                  .read<ProfitLossReportBloc>()
                  .add(ProfitLossReportSetGroupByEvent(value));
            }
          },
          items: [
            for (final groupBy in ProfitLossGroupBy.values)
              ComboBoxItem(
                value: groupBy,
                child: Text(groupBy.name),
              ),
          ],
        )
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
        const Text('Sort By: '),
        Spacing.h8,
        ComboBox(
          value: context.select((ProfitLossReportBloc b) => b.state.queryData.sortBy),
          onChanged: (value) {
            if (value != null) {
              context //
                  .read<ProfitLossReportBloc>()
                  .add(ProfitLossReportSetSortByEvent(value));
            }
          },
          items: [
            for (final sortBy in ProfitLossSortBy.values)
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

class _TakeSelection extends StatelessWidget {
  const _TakeSelection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Row Limit: '),
        Spacing.h8,
        Expanded(
          child: NumberBox<int>(
            value: context.select((ProfitLossReportBloc b) => b.state.queryData.take),
            onChanged: (value) {
              if (value != null && value > 0) {
                context //
                    .read<ProfitLossReportBloc>()
                    .add(ProfitLossReportSetTakeEvent(value));
              }
            },
            min: 1,
            max: 1000,
            smallChange: 1,
            largeChange: 10,
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
    return BlocBuilder<ProfitLossReportBloc, ProfitLossReportState>(
      builder: (context, reportState) {
        final profitLossData = reportState.queryData.profitLossDataWithTake ?? [];

        return Row(
          children: [
            TextButtonFilled(
              'Generate P&L Report',
              onPressed: reportState.isGenerating
                  ? null
                  : () => unawaited(_previewReport(context, reportState, profitLossData)),
            ),
          ],
        );
      },
    );
  }
}

class ProfitLossReportPreview extends StatelessWidget {
  const ProfitLossReportPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubheadingText('Report Preview'),
        Spacing.v12,
        _ProfitLossTablePreview(),
      ],
    );
  }
}

class _ProfitLossTablePreview extends StatelessWidget {
  const _ProfitLossTablePreview();

  @override
  Widget build(BuildContext context) {
    final data =
        context.select((ProfitLossReportBloc b) => b.state.queryData.profitLossDataWithTake) ?? [];

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
                for (final _ProfitLossColumn(:name, :flex) in profitLossColumns)
                  Expanded(flex: flex, child: BodyText(name, fontWeight: FontWeight.w600)),
              ].withSpacing(() => Spacing.h4),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final entry = data[index];

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
                    for (final _ProfitLossColumn(:flex, :value) in profitLossColumns)
                      Expanded(
                        flex: flex,
                        child: Text(
                          value(entry),
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
                for (final _ProfitLossColumn(:flex, :total) in profitLossColumns)
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
  }
}

// Static methods for PDF operations
Future<void> _previewReport(
  BuildContext context,
  ProfitLossReportState reportState,
  List<ProfitLossEntry> profitLossData,
) async {
  context.read<ProfitLossReportBloc>().add(const ProfitLossReportSetGeneratingEvent(true));

  try {
    /// Create the PDF overlay.
    showPdfOverlay(builder: (_, overlayEntry) {
      return MultiProvider(
        providers: [
          BlocProvider.value(value: context.read<ProfitLossReportBloc>()),
          BlocProvider.value(value: context.read<ProductListBloc>()),
          BlocProvider.value(value: context.read<InvoiceListBloc>()),
          BlocProvider.value(value: context.read<OrderListBloc>()),
        ],
        child: PdfOverlay(
          overlayEntry: overlayEntry,
          generatorCreator: () => _ProfitLossReportPdfGenerator(
            profitLossData: profitLossData,
            summary: reportState.queryData.summary,
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
      context.read<ProfitLossReportBloc>().add(const ProfitLossReportSetGeneratingEvent(false));
    }
  }
}

const _cellPadding = pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0);

// PDF generation methods
final class _ProfitLossReportPdfGenerator implements PdfGenerator {
  const _ProfitLossReportPdfGenerator({
    required this.profitLossData,
    this.summary,
    required this.startDate,
    required this.endDate,
  });

  final List<ProfitLossEntry> profitLossData;
  final ProfitLossSummary? summary;
  final DateTime startDate;
  final DateTime endDate;

  @override
  String get fileName =>
      'Profit_Loss_Report_${startDate.toIso8601String().split('T').first}_to_${endDate.toIso8601String().split('T').first}.pdf';

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
            if (summary != null) _buildSummarySection(summary!),
            pw.SizedBox(height: 20),
            // Profit & Loss Table
            pw.Table(
              border: pw.TableBorder.symmetric(),
              columnWidths: {
                for (final (index, _ProfitLossColumn(:width)) in profitLossColumns.indexed)
                  index: width,
              },
              children: [
                // Table Header
                _buildTableHeader(),

                // Table Rows
                for (final entry in profitLossData) _buildPdfRow(entry),

                _buildBottomRow(profitLossData),
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
                  'Profit and Loss Report',
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

  pw.Widget _buildSummarySection(ProfitLossSummary summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryBox('Total Revenue', summary.totalRevenue),
          _buildSummaryBox('Total Expenses', summary.totalExpenses),
          _buildSummaryBox('Net Profit', summary.totalProfit),
          _buildSummaryBox('Profit Margin', summary.averageProfitMargin, isPercentage: true),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryBox(String title, double value, {bool isPercentage = false}) {
    final formattedValue =
        isPercentage ? '${value.toStringAsFixed(2)}%' : 'Php ${value.toStringAsFixed(2)}';

    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              formattedValue,
              style: const pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  pw.TableRow _buildTableHeader() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      children: [
        for (final _ProfitLossColumn(:name) in profitLossColumns)
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

  pw.TableRow _buildPdfRow(ProfitLossEntry entry) {
    return pw.TableRow(
      children: [
        for (final _ProfitLossColumn(:value) in profitLossColumns)
          pw.Padding(
            padding: _cellPadding,
            child: pw.Text(
              value(entry),
              style: const pw.TextStyle(fontSize: 8),
              softWrap: false,
              overflow: pw.TextOverflow.span,
            ),
          ),
      ],
    );
  }

  pw.TableRow _buildBottomRow(List<ProfitLossEntry> data) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      children: [
        for (final _ProfitLossColumn(:total) in profitLossColumns)
          if (total != null)
            pw.Padding(
              padding: _cellPadding,
              child: pw.Text(
                total(data),
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
