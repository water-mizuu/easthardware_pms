import 'dart:async';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/payment.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/payment/payment_list/payment_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/sales/invoice_sales_report/invoice_sales_report_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/reports/common/reports_globals.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_generation.dart';
import 'package:easthardware_pms/presentation/views/reports/sales_report/invoice_sales_query_data.dart';
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

typedef InvoiceSalesRecordData = (Invoice, List<Payment>);
typedef InvoiceSalesValueFunction = String Function(InvoiceSalesRecordData);
typedef TotalInvoiceSalesFunction = String Function(List<InvoiceSalesRecordData>);
typedef _InvoiceSalesColumnRecord = (
  String name,
  int flex,
  pw.TableColumnWidth width,
  InvoiceSalesValueFunction value,
  TotalInvoiceSalesFunction? total,
);

extension type const _InvoiceSalesColumn._(_InvoiceSalesColumnRecord record) {
  const _InvoiceSalesColumn({
    required String name,
    int flex = 1,
    required pw.TableColumnWidth width,
    required InvoiceSalesValueFunction value,
    TotalInvoiceSalesFunction? total,
  }) : this._((name, flex, width, value, total));

  String get name => record.$1;
  int get flex => record.$2;
  pw.TableColumnWidth get width => record.$3;
  InvoiceSalesValueFunction get value => record.$4;
  TotalInvoiceSalesFunction? get total => record.$5;
}

final invoiceSalesColumns = <_InvoiceSalesColumn>[
  _InvoiceSalesColumn(
    name: 'Invoice #',
    flex: 1,
    width: const pw.FlexColumnWidth(1),
    value: (args) => '#${args.$1.id}',
    total: (args) => 'Total',
  ),
  _InvoiceSalesColumn(
    name: 'Customer',
    flex: 2,
    width: const pw.FlexColumnWidth(2),
    value: (args) => args.$1.customerName.isEmpty ? 'N/A' : args.$1.customerName,
  ),
  _InvoiceSalesColumn(
    name: 'Invoice Date',
    flex: 1,
    width: const pw.FlexColumnWidth(1),
    value: (args) => DateFormat('MM/dd/yyyy').format(args.$1.invoiceDate),
  ),
  _InvoiceSalesColumn(
    name: 'Due Date',
    flex: 1,
    width: const pw.FlexColumnWidth(1),
    value: (args) => DateFormat('MM/dd/yyyy').format(args.$1.dueDate),
  ),
  _InvoiceSalesColumn(
    name: 'Amount Due',
    flex: 1,
    width: const pw.FlexColumnWidth(1),
    value: (args) => CurrencyFormatter.full(args.$1.amountDue),
    total: (data) => CurrencyFormatter.full(data.fold(0.0, (a, b) => a + b.$1.amountDue)),
  ),
  _InvoiceSalesColumn(
    name: 'Amount Paid',
    flex: 1,
    width: const pw.FlexColumnWidth(1),
    value: (args) {
      // Use invoice's amountPaid field if available, otherwise calculate from payments
      final totalPaid = (args.$1.amountPaid ?? 0.0) +
          args.$2.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      return CurrencyFormatter.full(totalPaid);
    },
    total: (data) => CurrencyFormatter.full(data.fold(0.0, (a, b) {
      final totalPaid =
          (b.$1.amountPaid ?? 0.0) + b.$2.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      return a + totalPaid;
    })),
  ),
  _InvoiceSalesColumn(
    name: 'Balance Due',
    flex: 1,
    width: const pw.FlexColumnWidth(1),
    value: (args) {
      final totalPaid = (args.$1.amountPaid ?? 0.0) +
          args.$2.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      final balance = args.$1.amountDue - totalPaid;
      return CurrencyFormatter.full(balance);
    },
    total: (data) => CurrencyFormatter.full(data.fold<double>(0.0, (a, b) {
      final totalPaid =
          (b.$1.amountPaid ?? 0.0) + b.$2.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      return a + (b.$1.amountDue - totalPaid);
    })),
  ),
  _InvoiceSalesColumn(
    name: 'Status',
    flex: 1,
    width: const pw.FlexColumnWidth(1),
    value: (args) {
      final totalPaid =
          args.$1.amountPaid ?? args.$2.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      final balance = args.$1.amountDue - totalPaid;
      if (balance <= 0) {
        return 'Paid';
      } else if (totalPaid > 0) {
        return 'Partial';
      } else {
        return 'Unpaid';
      }
    },
  ),
];

class InvoiceSalesReportPage extends StatelessWidget {
  const InvoiceSalesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvoiceSalesReportBloc(
        context.read<InvoiceListBloc>().state.invoices,
        context.read<PaymentListBloc>().state.payments,
      ),
      child: Builder(builder: (context) {
        return MultiBlocListener(
          listeners: [
            BlocListener<InvoiceListBloc, InvoiceListState>(
              listenWhen: (p, c) => p.invoices != c.invoices,
              listener: (context, state) {
                context
                    .read<InvoiceSalesReportBloc>()
                    .add(InvoiceSalesReportUpdateInvoicesEvent(state.invoices));
              },
            ),
            BlocListener<PaymentListBloc, PaymentListState>(
              listenWhen: (p, c) => p.payments != c.payments,
              listener: (context, state) {
                context
                    .read<InvoiceSalesReportBloc>()
                    .add(InvoiceSalesReportUpdatePaymentsEvent(state.payments));
              },
            ),
          ],
          child: const Padding(
            padding: AppPadding.panePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InvoiceSalesReportHeader(),
                Spacing.v16,
                Expanded(
                  child: AnimatedSingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InvoiceSalesReportOptions(),
                        Spacing.v32,
                        InvoiceSalesReportPreview(),
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

class InvoiceSalesReportHeader extends StatelessWidget {
  const InvoiceSalesReportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => context.navigate(AppRoutes.admin.reports),
              ),
              Spacing.h16,
              const DisplayText('Invoice Sales Report'),
            ],
          ),
        ),
        Spacing.h24,
        Row(
          children: [
            Builder(
              builder: (context) {
                final state = context.watch<InvoiceSalesReportBloc>().state;

                return TextButtonFilled(
                  state.isGenerating ? 'Generating...' : 'Preview Report',
                  onPressed: () {
                    if (state.isGenerating) return null;

                    return () {
                      final state = context.read<InvoiceSalesReportBloc>().state;
                      final invoiceSalesData = state.queryData.invoiceSalesDataWithRowLimit;
                      if (invoiceSalesData == null || invoiceSalesData.isEmpty) {
                        showNotification.warning(
                          title: 'No data',
                          message: 'There are no invoices to generate a report for.',
                        );
                        return;
                      }
                      unawaited(_previewReport(context, state, invoiceSalesData));
                    };
                  }(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class InvoiceSalesReportOptions extends StatelessWidget {
  const InvoiceSalesReportOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SubheadingText('Report Options'),
        Spacing.v12,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 80, child: BodyText('Start Date: ')),
                Spacing.v8,
                BlocBuilder<InvoiceSalesReportBloc, InvoiceSalesReportState>(
                  buildWhen: (previous, current) =>
                      previous.queryData.startDate != current.queryData.startDate,
                  builder: (context, state) {
                    return BorderedDatePicker(
                      selected: state.queryData.startDate,
                      onChanged: (date) => context
                          .read<InvoiceSalesReportBloc>()
                          .add(InvoiceSalesReportSetStartDateEvent(date)),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 80, child: BodyText('End Date: ')),
                Spacing.v8,
                BlocBuilder<InvoiceSalesReportBloc, InvoiceSalesReportState>(
                  buildWhen: (previous, current) =>
                      previous.queryData.endDate != current.queryData.endDate,
                  builder: (context, state) {
                    return BorderedDatePicker(
                      selected: state.queryData.endDate,
                      onChanged: (date) => context
                          .read<InvoiceSalesReportBloc>()
                          .add(InvoiceSalesReportSetEndDateEvent(date)),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 80, child: BodyText('Status: ')),
                Spacing.v8,
                BlocBuilder<InvoiceSalesReportBloc, InvoiceSalesReportState>(
                  buildWhen: (previous, current) =>
                      previous.queryData.statusFilter != current.queryData.statusFilter,
                  builder: (context, state) {
                    return ComboBox<InvoiceStatusFilter>(
                      value: state.queryData.statusFilter,
                      items: InvoiceStatusFilter.values
                          .map((e) => ComboBoxItem(value: e, child: Text(e.name)))
                          .toList(),
                      onChanged: (value) => context
                          .read<InvoiceSalesReportBloc>()
                          .add(InvoiceSalesReportSetStatusFilterEvent(value!)),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 80, child: BodyText('Customer: ')),
                Spacing.v8,
                BlocBuilder<InvoiceSalesReportBloc, InvoiceSalesReportState>(
                  buildWhen: (previous, current) =>
                      previous.queryData.selectedCustomer != current.queryData.selectedCustomer,
                  builder: (context, state) {
                    // Create a unique list of customer names from the invoices
                    final customers = state.allInvoices
                        .map((e) => e.customerName)
                        .where((name) => name.isNotEmpty)
                        .toSet()
                        .toList()
                      ..sort();

                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: ComboBox<String?>(
                        placeholder: const Text('All Customers'),
                        value: state.queryData.selectedCustomer,
                        items: [
                          const ComboBoxItem<String?>(
                            value: null,
                            child: Text('All Customers'),
                          ),
                          for (final customer in customers)
                            ComboBoxItem<String?>(
                              value: customer,
                              child: Text(customer),
                            ),
                        ],
                        onChanged: (value) => context
                            .read<InvoiceSalesReportBloc>()
                            .add(InvoiceSalesReportSetCustomerEvent(value)),
                      ),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 80, child: BodyText('Search: ')),
                Spacing.v8,
                BlocBuilder<InvoiceSalesReportBloc, InvoiceSalesReportState>(
                  buildWhen: (previous, current) =>
                      previous.queryData.searchQuery != current.queryData.searchQuery,
                  builder: (context, state) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: TextBox(
                        placeholder: 'Search invoices...',
                        controller: TextEditingController(text: state.queryData.searchQuery),
                        onChanged: (value) => context
                            .read<InvoiceSalesReportBloc>()
                            .add(InvoiceSalesReportSetSearchQueryEvent(value)),
                      ),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 80, child: BodyText('Sort By: ')),
                Spacing.v8,
                BlocBuilder<InvoiceSalesReportBloc, InvoiceSalesReportState>(
                  buildWhen: (previous, current) =>
                      previous.queryData.sortBy != current.queryData.sortBy,
                  builder: (context, state) {
                    return ComboBox<InvoiceSalesReportSortBy>(
                      value: state.queryData.sortBy,
                      items: InvoiceSalesReportSortBy.values
                          .map((e) => ComboBoxItem(value: e, child: Text(e.name)))
                          .toList(),
                      onChanged: (value) => context
                          .read<InvoiceSalesReportBloc>()
                          .add(InvoiceSalesReportSetSortByEvent(value!)),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 80, child: BodyText('Row Limit: ')),
                Spacing.v8,
                BlocBuilder<InvoiceSalesReportBloc, InvoiceSalesReportState>(
                  buildWhen: (previous, current) =>
                      previous.queryData.rowLimit != current.queryData.rowLimit,
                  builder: (context, state) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 120,
                        maxWidth: 180,
                      ),
                      child: NumberBox<int>(
                        value: state.queryData.rowLimit,
                        min: 1,
                        mode: SpinButtonPlacementMode.none,
                        clearButton: false,
                        placeholder: 'All',
                        onChanged: (value) => context
                            .read<InvoiceSalesReportBloc>()
                            .add(InvoiceSalesReportSetRowLimitEvent(value)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ].withSpacing(() => Spacing.v8),
        ),
      ],
    );
  }
}

class InvoiceSalesReportPreview extends StatelessWidget {
  const InvoiceSalesReportPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.cardPadding,
      color: FluentTheme.of(context).cardColor,
      child: BlocBuilder<InvoiceSalesReportBloc, InvoiceSalesReportState>(
        builder: (context, state) {
          final invoiceSalesData = state.queryData.invoiceSalesDataWithRowLimit;

          if (invoiceSalesData == null || invoiceSalesData.isEmpty) {
            return const Center(
              child: Column(
                children: [
                  Icon(FluentIcons.document_search, size: 48),
                  Spacing.v16,
                  Text('No invoices found for the selected date range.'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Section
              _buildSummarySection(invoiceSalesData),
              Spacing.v24,
              // Header Row
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).menuColor,
                ),
                child: Row(
                  children: [
                    for (final _InvoiceSalesColumn(:name, :flex) in invoiceSalesColumns)
                      Expanded(
                        flex: flex,
                        child: Text(
                          name,
                          style: TextStyles.body.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ].withSpacing(() => Spacing.h4),
                ),
              ),
              // Data Rows
              ...invoiceSalesData.asMap().entries.map((entry) {
                final invoiceData = entry.value;
                return Container(
                  padding: const EdgeInsets.all(6.0),
                  child: Row(
                    children: [
                      for (final _InvoiceSalesColumn(:flex, :value) in invoiceSalesColumns)
                        Expanded(
                          flex: flex,
                          child: Text(
                            value(invoiceData),
                            style: TextStyles.body,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ].withSpacing(() => Spacing.h4),
                  ),
                );
              }),
              // Total Row
              Container(
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  children: ([
                    for (final _InvoiceSalesColumn(:flex, :total) in invoiceSalesColumns)
                      if (total != null)
                        Expanded(
                          flex: flex,
                          child: Text(
                            total(invoiceSalesData),
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
          );
        },
      ),
    );
  }

  Widget _buildSummarySection(List<(Invoice, List<Payment>)> invoiceSalesData) {
    return Builder(
      builder: (context) {
        final totalInvoices = invoiceSalesData.length;
        final totalAmountDue =
            invoiceSalesData.fold<double>(0.0, (sum, item) => sum + item.$1.amountDue);
        final totalAmountPaid = invoiceSalesData.fold<double>(0.0, (sum, item) {
          final totalPaid = (item.$1.amountPaid ?? 0.0) +
              item.$2.fold<double>(0.0, (sum, payment) => sum + payment.amount);
          return sum + totalPaid;
        });
        final totalBalanceDue = totalAmountDue - totalAmountPaid;
        final paidCount = invoiceSalesData.where((item) {
          final totalPaid = (item.$1.amountPaid ?? 0.0) +
              item.$2.fold<double>(0.0, (sum, payment) => sum + payment.amount);
          return totalPaid >= item.$1.amountDue;
        }).length;
        return Container(
          padding: AppPadding.cardPadding,
          decoration: BoxDecoration(
            color: FluentTheme.of(context).menuColor.withOpacity(0.1),
          ),
          child: Row(
            children: [
              Expanded(
                child: ReportsGlobals.summaryItem(
                  'Total Invoices',
                  totalInvoices.toString(),
                  FluentIcons.receipt_processing,
                ),
              ),
              Expanded(
                child: ReportsGlobals.summaryItem(
                  'Total Amount Due',
                  CurrencyFormatter.full(totalAmountDue),
                  FluentIcons.money,
                ),
              ),
              Expanded(
                child: ReportsGlobals.summaryItem(
                  'Total Amount Paid',
                  CurrencyFormatter.full(totalAmountPaid),
                  FluentIcons.check_mark,
                ),
              ),
              Expanded(
                child: ReportsGlobals.summaryItem(
                  'Total Balance Due',
                  CurrencyFormatter.full(totalBalanceDue),
                  FluentIcons.timer,
                ),
              ),
              Expanded(
                child: ReportsGlobals.summaryItem(
                  'Paid Invoices',
                  '$paidCount/$totalInvoices',
                  FluentIcons.completed,
                ),
              ),
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
  InvoiceSalesReportState reportState,
  List<(Invoice, List<Payment>)> invoiceSalesData,
) async {
  context.read<InvoiceSalesReportBloc>().add(const InvoiceSalesReportSetGeneratingEvent(true));

  try {
    showPdfOverlay(builder: (_, overlayEntry) {
      return MultiProvider(
        providers: [
          BlocProvider.value(value: context.read<InvoiceSalesReportBloc>()),
          BlocProvider.value(value: context.read<InvoiceListBloc>()),
          BlocProvider.value(value: context.read<PaymentListBloc>()),
        ],
        child: PdfOverlay(
          overlayEntry: overlayEntry,
          generatorCreator: () => _InvoiceSalesReportPdfGenerator(
            invoiceSalesData: invoiceSalesData,
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
      context.read<InvoiceSalesReportBloc>().add(const InvoiceSalesReportSetGeneratingEvent(false));
    }
  }
}

const _cellPadding = pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0);

// PDF generation methods
final class _InvoiceSalesReportPdfGenerator implements PdfGenerator {
  const _InvoiceSalesReportPdfGenerator({
    required this.invoiceSalesData,
    required this.startDate,
    required this.endDate,
  });

  final List<(Invoice, List<Payment>)> invoiceSalesData;
  final DateTime startDate;
  final DateTime endDate;

  @override
  String get fileName =>
      'Invoice_Sales_Report_${startDate.toIso8601String().split('T').first}_to_${endDate.toIso8601String().split('T').first}.pdf';

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
            // Summary section
            _buildInvoiceSummary(context, invoiceSalesData),
            pw.SizedBox(height: 15),

            // Invoice Sales Table
            pw.Table(
              border: pw.TableBorder.symmetric(),
              columnWidths: {
                for (final (index, _InvoiceSalesColumn(:width)) in invoiceSalesColumns.indexed)
                  index: width,
              },
              children: [
                // Table Header
                _buildPdfInvoiceSalesHeader(),

                // Table Rows
                for (final invoiceData in invoiceSalesData) _buildPdfInvoiceSalesItem(invoiceData),

                _buildBottomRow(invoiceSalesData),
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
                  'Invoice Sales Report',
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

  pw.Widget _buildInvoiceSummary(
      pw.Context context, List<(Invoice, List<Payment>)> invoiceSalesData) {
    final totalInvoices = invoiceSalesData.length;
    final totalAmountDue =
        invoiceSalesData.fold<double>(0.0, (sum, item) => sum + item.$1.amountDue);
    final totalAmountPaid = invoiceSalesData.fold<double>(0.0, (sum, item) {
      final totalPaid =
          item.$1.amountPaid ?? item.$2.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      return sum + totalPaid;
    });
    final totalBalanceDue = totalAmountDue - totalAmountPaid;
    final paidCount = invoiceSalesData.where((item) {
      final totalPaid =
          item.$1.amountPaid ?? item.$2.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      return totalPaid >= item.$1.amountDue;
    }).length;
    final overpaidCount = invoiceSalesData.where((item) {
      final totalPaid =
          item.$1.amountPaid ?? item.$2.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      return totalPaid > item.$1.amountDue;
    }).length;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildPdfSummaryItem('Total Invoices', totalInvoices.toString()),
        _buildPdfSummaryItem('Total Amount Due', CurrencyFormatter.full(totalAmountDue)),
        _buildPdfSummaryItem('Total Amount Paid', CurrencyFormatter.full(totalAmountPaid)),
        _buildPdfSummaryItem('Total Balance Due', CurrencyFormatter.full(totalBalanceDue)),
        _buildPdfSummaryItem('Paid Invoices', paidCount.toString()),
        if (overpaidCount > 0) _buildPdfSummaryItem('Overpaid Invoices', overpaidCount.toString()),
      ],
    );
  }

  pw.Widget _buildPdfSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  pw.TableRow _buildPdfInvoiceSalesHeader() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      children: [
        for (final _InvoiceSalesColumn(:name) in invoiceSalesColumns)
          pw.Padding(
            padding: _cellPadding,
            child: pw.Text(
              name,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            ),
          ),
      ],
    );
  }

  pw.TableRow _buildPdfInvoiceSalesItem((Invoice, List<Payment>) invoiceData) {
    return pw.TableRow(
      children: [
        for (final _InvoiceSalesColumn(:value) in invoiceSalesColumns)
          pw.Padding(
            padding: _cellPadding,
            child: pw.Text(
              value(invoiceData),
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
      ],
    );
  }

  pw.TableRow _buildBottomRow(List<(Invoice, List<Payment>)> invoiceSalesData) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      children: [
        for (final _InvoiceSalesColumn(:total) in invoiceSalesColumns)
          if (total != null)
            pw.Padding(
              padding: _cellPadding,
              child: pw.Text(
                total(invoiceSalesData),
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
