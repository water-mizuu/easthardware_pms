import 'dart:async';
import 'dart:io';

import 'package:easthardware_pms/presentation/bloc/business_snapshot/business_snapshot_report_bloc.dart';
import 'package:easthardware_pms/presentation/views/reports/business_snapshot/business_snapshot_query_data.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/presentation/widgets/layout/spacing.dart';
import 'package:easthardware_pms/presentation/widgets/text.dart';
import 'package:easthardware_pms/utils/notification.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Business Snapshot Report Page
/// This page displays a comprehensive snapshot of business performance
class BusinessSnapshotReport extends StatefulWidget {
  const BusinessSnapshotReport({super.key});

  @override
  State<BusinessSnapshotReport> createState() => _BusinessSnapshotReportState();
}

class _BusinessSnapshotReportState extends State<BusinessSnapshotReport> {
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    context.read<BusinessSnapshotReportBloc>().add(
          const BusinessSnapshotReportInitializeEvent(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessSnapshotReportBloc, BusinessSnapshotReportState>(
      builder: (context, state) {
        return ScaffoldPage.scrollable(
          header: const PageHeader(title: Text('Business Snapshot Report')),
          children: [
            Spacing.v16,
            _buildFilters(context, state),
            Spacing.v16,
            _buildKeyMetricsSection(context, state),
            Spacing.v16,
            _buildTopProductsSection(context, state),
            Spacing.v16,
            _buildExpenseBreakdownSection(context, state),
            Spacing.v16,
            _buildSalesHistorySection(context, state),
            Spacing.v16,
            _buildReportActionButtons(context, state),
          ],
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context, BusinessSnapshotReportState state) {
    return Card(
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SubheadingText('Report Filters'),
            Spacing.v8,
            Row(
              children: [
                Expanded(
                  child: DatePicker(
                    selected: state.queryData.currentPeriodStart,
                    onChanged: (date) {
                      context.read<BusinessSnapshotReportBloc>().add(
                            BusinessSnapshotReportSetStartDateEvent(date),
                          );
                    },
                  ),
                ),
                Spacing.h16,
                Expanded(
                  child: DatePicker(
                    selected: state.queryData.currentPeriodEnd,
                    onChanged: (date) {
                      context.read<BusinessSnapshotReportBloc>().add(
                            BusinessSnapshotReportSetEndDateEvent(date),
                          );
                    },
                  ),
                ),
              ],
            ),
            Spacing.v8,
            Row(
              children: [
                Expanded(
                  child: ComboBox<BusinessSnapshotPeriod>(
                    value: state.queryData.comparisonPeriod,
                    items: BusinessSnapshotPeriod.values
                        .map((period) => ComboBoxItem<BusinessSnapshotPeriod>(
                              value: period,
                              child: Text(period.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<BusinessSnapshotReportBloc>().add(
                              BusinessSnapshotReportSetComparisonPeriodEvent(value),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsSection(BuildContext context, BusinessSnapshotReportState state) {
    final metrics = state.queryData.keyMetrics ?? [];

    return Card(
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SubheadingText('Key Business Metrics'),
                Spacing.v8,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Sort by:'),
                    SizedBox(
                      width: 180,
                      child: ComboBox<BusinessMetricSortBy>(
                        value: state.queryData.keyMetricsSortBy,
                        items: BusinessMetricSortBy.values
                            .map((option) => ComboBoxItem<BusinessMetricSortBy>(
                                  value: option,
                                  child: Text(option.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            context.read<BusinessSnapshotReportBloc>().add(
                                  BusinessSnapshotReportSetKeyMetricsSortByEvent(value),
                                );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacing.v16,
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: metrics.length,
              itemBuilder: (context, index) {
                final metric = metrics[index];
                return _buildMetricCard(metric);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BusinessMetric metric) {
    final trendIcon = metric.isPositiveChange
        ? Icon(FluentIcons.chevron_up, color: Colors.green)
        : Icon(FluentIcons.chevron_down, color: Colors.red);

    return Card(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.full(metric.currentValue, "Php "),
                style: const TextStyle(fontSize: 16),
              ),
              Row(
                children: [
                  trendIcon,
                  Spacing.h4,
                  Text(
                    '${metric.percentageChange.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: metric.isPositiveChange ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection(BuildContext context, BusinessSnapshotReportState state) {
    final topProducts = state.queryData.topSellingProducts ?? [];

    return Card(
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SubheadingText('Top Performing Products'),
                Spacing.v8,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Sort by:'),
                    SizedBox(
                      width: 180,
                      child: ComboBox<TopSellingProductSortBy>(
                        value: state.queryData.topProductsSortBy,
                        items: TopSellingProductSortBy.values
                            .map((option) => ComboBoxItem<TopSellingProductSortBy>(
                                  value: option,
                                  child: Text(option.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            context.read<BusinessSnapshotReportBloc>().add(
                                  BusinessSnapshotReportSetTopProductsSortByEvent(value),
                                );
                          }
                        },
                      ),
                    ),
                    const Text('Show:'),
                    SizedBox(
                      width: 80,
                      child: NumberBox<int>(
                        value: state.queryData.maxTopProducts,
                        min: 3,
                        max: 20,
                        onChanged: (value) {
                          if (value != null) {
                            context.read<BusinessSnapshotReportBloc>().add(
                                  BusinessSnapshotReportSetMaxTopProductsEvent(value),
                                );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacing.v16,
            Table(
              border: TableBorder.all(color: Colors.grey[30]),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Colors.white),
                  children: [
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Quantity Sold', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Profit', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                ...topProducts.map((product) => TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(product.product.name),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(product.quantitySold.toStringAsFixed(2)),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(CurrencyFormatter.full(product.revenue, "Php ")),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(CurrencyFormatter.full(product.profit, "Php ")),
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdownSection(BuildContext context, BusinessSnapshotReportState state) {
    final expenses = state.queryData.expenseBreakdown ?? [];

    return Card(
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SubheadingText('Expense Breakdown'),
                Spacing.v8,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Sort by:'),
                    SizedBox(
                      width: 180,
                      child: ComboBox<ExpenseBreakdownSortBy>(
                        value: state.queryData.expenseBreakdownSortBy,
                        items: ExpenseBreakdownSortBy.values
                            .map((option) => ComboBoxItem<ExpenseBreakdownSortBy>(
                                  value: option,
                                  child: Text(option.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            context.read<BusinessSnapshotReportBloc>().add(
                                  BusinessSnapshotReportSetExpenseBreakdownSortByEvent(value),
                                );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacing.v16,
            Table(
              border: TableBorder.all(color: Colors.grey[30]),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Colors.white),
                  children: [
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Expense Type', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                ...expenses.map((expense) => TableRow(
                      children: [
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(expense.expenseType.name),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(CurrencyFormatter.full(expense.amount, "Php ")),
                          ),
                        ),
                        TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('${expense.percentage.toStringAsFixed(1)}%'),
                          ),
                        ),
                      ],
                    )),
                TableRow(
                  decoration: const BoxDecoration(color: Colors.white),
                  children: [
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          CurrencyFormatter.full(
                            expenses.fold<double>(0, (sum, expense) => sum + expense.amount),
                            "Php ",
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('100%', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesHistorySection(BuildContext context, BusinessSnapshotReportState state) {
    // In a real implementation this would use a chart library like fl_chart
    // For now, we'll simulate a chart with a placeholder
    return Card(
      child: Padding(
        padding: AppPadding.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SubheadingText('Sales History'),
            Spacing.v16,
            SizedBox(
              key: _chartKey,
              height: 300,
              child: const Center(
                child: Text(
                  'Sales history chart would be displayed here\n(Using fl_chart or another charting library)',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportActionButtons(BuildContext context, BusinessSnapshotReportState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Button(
          onPressed: () async {
            _generatePdfReport(context, state);
          },
          child: const Text('Generate PDF Report'),
        ),
        Spacing.h8,
        FilledButton(
          onPressed: () async {
            _generatePdfReport(context, state, shouldPrint: true);
          },
          child: const Text('Print Report'),
        ),
      ],
    );
  }

  Future<void> _generatePdfReport(
    BuildContext context,
    BusinessSnapshotReportState state, {
    bool shouldPrint = false,
  }) async {
    context.read<BusinessSnapshotReportBloc>().add(
          const BusinessSnapshotReportSetGeneratingEvent(true),
        );

    try {
      final pdf = pw.Document();

      // Add PDF generation logic here, similar to other reports
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) {
            return pw.Center(
              child: pw.Text(
                'Business Snapshot Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
          footer: (context) {
            return pw.Center(
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 12,
                ),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Business Snapshot Report',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Paragraph(
                text:
                    'Report Period: ${DateFormat('MMM d, yyyy').format(state.queryData.currentPeriodStart)} to ${DateFormat('MMM d, yyyy').format(state.queryData.currentPeriodEnd)}',
              ),
              pw.SizedBox(height: 16),

              // Key Metrics Section
              pw.Header(level: 2, text: 'Key Business Metrics'),
              pw.SizedBox(height: 8),
              _buildPdfMetricsTable(state),
              pw.SizedBox(height: 16),

              // Top Products Section
              pw.Header(level: 2, text: 'Top Performing Products'),
              pw.SizedBox(height: 8),
              _buildPdfTopProductsTable(state),
              pw.SizedBox(height: 16),

              // Expense Breakdown Section
              pw.Header(level: 2, text: 'Expense Breakdown'),
              pw.SizedBox(height: 8),
              _buildPdfExpenseBreakdownTable(state),
              pw.SizedBox(height: 16),

              // Sales History Chart placeholder (in real implementation, you would capture the chart)
              pw.Header(level: 2, text: 'Sales History'),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 200,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text('Sales history chart would be displayed here'),
              ),
            ];
          },
        ),
      );

      final fileName =
          'business_snapshot_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}';

      if (shouldPrint) {
        await Printing.layoutPdf(onLayout: (format) => pdf.save());

        showNotification(
          title: 'Success',
          message: 'Business Snapshot Report sent to printer',
        );
      } else {
        final bytes = await pdf.save();

        try {
          final path = await FilePicker.platform.saveFile(
            dialogTitle: 'Save PDF Report',
            fileName: '$fileName.pdf',
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );

          if (path != null) {
            final file = File(path);
            await file.writeAsBytes(bytes);

            showNotification(
              title: 'Success',
              message: 'Business Snapshot Report generated successfully',
            );
          }
        } catch (e) {
          showNotification(
            title: 'Error',
            message: 'Failed to save PDF file: $e',
            severity: InfoBarSeverity.error,
          );
        }
      }
    } catch (e) {
      showNotification(
        title: 'Error',
        message: 'Failed to generate PDF report: $e',
        severity: InfoBarSeverity.error,
      );
    } finally {
      context.read<BusinessSnapshotReportBloc>().add(
            const BusinessSnapshotReportSetGeneratingEvent(false),
          );
    }
  }

  pw.Widget _buildPdfMetricsTable(BusinessSnapshotReportState state) {
    final metrics = state.queryData.keyMetrics ?? [];

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('Metric Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('Current Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('Previous Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('Change %', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...metrics.map((metric) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(metric.name),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(CurrencyFormatter.full(metric.currentValue, "Php ")),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(CurrencyFormatter.full(metric.previousValue, "Php ")),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(
                    '${metric.percentageChange >= 0 ? "+" : ""}${metric.percentageChange.toStringAsFixed(1)}%',
                  ),
                ),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildPdfTopProductsTable(BusinessSnapshotReportState state) {
    final products = state.queryData.topSellingProducts ?? [];

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('Product Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('Quantity Sold', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('Revenue', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('Profit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...products.map((product) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(product.product.name),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(product.quantitySold.toStringAsFixed(2)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(CurrencyFormatter.full(product.revenue, "Php ")),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(CurrencyFormatter.full(product.profit, "Php ")),
                ),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildPdfExpenseBreakdownTable(BusinessSnapshotReportState state) {
    final expenses = state.queryData.expenseBreakdown ?? [];

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('Expense Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('Percentage', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...expenses.map((expense) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(expense.expenseType.name),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(CurrencyFormatter.full(expense.amount, "Php ")),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text('${expense.percentage.toStringAsFixed(1)}%'),
                ),
              ],
            )),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text(
                CurrencyFormatter.full(
                  expenses.fold<double>(0, (sum, expense) => sum + expense.amount),
                  "Php ",
                ),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8.0),
              child: pw.Text('100%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
