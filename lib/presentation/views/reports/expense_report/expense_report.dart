import 'dart:async';

import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/presentation/bloc/order/expense_report/expense_report_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/'
    'expense_type_list/expense_type_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/reports/'
    'expense_report/expense_query_data.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_generation.dart';
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

typedef ExpenseRecordData = (Order, ExpenseType);
typedef ExpenseValueFunction = String Function(ExpenseRecordData);
typedef TotalExpenseFunction = String Function(List<ExpenseRecordData>);
typedef _ExpenseColumnRecord = (
  String name,
  int flex,
  pw.TableColumnWidth width,
  ExpenseValueFunction value,
  TotalExpenseFunction? total,
);

extension type const _ExpenseColumn._(_ExpenseColumnRecord record) {
  const _ExpenseColumn({
    required String name,
    int flex = 1,
    required pw.TableColumnWidth width,
    required ExpenseValueFunction value,
    TotalExpenseFunction? total,
  }) : this._((name, flex, width, value, total));

  String get name => record.$1;
  int get flex => record.$2;
  pw.TableColumnWidth get width => record.$3;
  ExpenseValueFunction get value => record.$4;
  TotalExpenseFunction? get total => record.$5;
}

final expenseColumns = <_ExpenseColumn>[
  _ExpenseColumn(
    name: 'Expense Type',
    flex: 2,
    width: const pw.FlexColumnWidth(2),
    value: (args) => args.expenseType.name,
    total: (args) => 'Total',
  ),
  _ExpenseColumn(
    name: 'Payee',
    flex: 2,
    width: const pw.FlexColumnWidth(2),
    value: (args) => args.order.payeeName,
  ),
  _ExpenseColumn(
    name: 'Date',
    width: const pw.FlexColumnWidth(1),
    value: (args) => DateFormat('MM/dd/yyyy').format(args.order.orderDate),
  ),
  _ExpenseColumn(
    name: 'Amount Paid',
    width: const pw.FlexColumnWidth(1),
    value: (args) => CurrencyFormatter.full(args.order.amountDue, "Php "),
    total: (data) => CurrencyFormatter.full(data.fold(0, (a, b) => a + b.amountDue), "Php "),
  ),
];

class ExpenseReportPage extends StatelessWidget {
  const ExpenseReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ExpenseReportBloc(
        context.read<OrderListBloc>().state.allOrders,
        context.read<ExpenseTypeListBloc>().state.expenseTypes,
      ),
      child: Builder(builder: (context) {
        return MultiBlocListener(
          listeners: [
            BlocListener<OrderListBloc, OrderListState>(
              listenWhen: (p, c) => p.allOrders != c.allOrders,
              listener: (context, state) {
                context
                    .read<ExpenseReportBloc>()
                    .add(ExpenseReportUpdateOrdersEvent(state.allOrders));
              },
            ),
            BlocListener<ExpenseTypeListBloc, ExpenseTypeListState>(
              listenWhen: (p, c) => p.expenseTypes != c.expenseTypes,
              listener: (context, state) {
                context
                    .read<ExpenseReportBloc>()
                    .add(ExpenseReportUpdateExpenseTypesEvent(state.expenseTypes));
              },
            ),
          ],
          child: const Padding(
            padding: AppPadding.panePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExpenseReportHeader(),
                Spacing.v16,
                Expanded(
                  child: AnimatedSingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpenseReportOptions(),
                        Spacing.v24,
                        ExpenseReportPreview(),
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

class ExpenseReportHeader extends StatelessWidget {
  const ExpenseReportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => context.navigate(AppRoutes.admin.reports),
        ),
        Spacing.h16,
        const DisplayText('Expense Report'),
      ],
    );
  }
}

class ExpenseReportOptions extends StatelessWidget {
  const ExpenseReportOptions({super.key});

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

class _StartDateSelection extends StatelessWidget {
  const _StartDateSelection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 80, child: Text('Start Date: ')),
        Spacing.h8,
        BorderedDatePicker(
          selected: context.select((ExpenseReportBloc b) => b.state.queryData.startDate),
          onChanged: (value) => context //
              .read<ExpenseReportBloc>()
              .add(ExpenseReportSetStartDateEvent(value)),
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
          selected: context.select((ExpenseReportBloc b) => b.state.queryData.endDate),
          onChanged: (value) => context //
              .read<ExpenseReportBloc>()
              .add(ExpenseReportSetEndDateEvent(value)),
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
          value: context.select((ExpenseReportBloc b) => b.state.queryData.sortBy),
          onChanged: (value) {
            if (value != null) {
              context //
                  .read<ExpenseReportBloc>()
                  .add(ExpenseReportSetSortByEvent(value));
            }
          },
          items: [
            for (final sortBy in ExpenseReportSortBy.values)
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
        const SizedBox(width: 80, child: Text('Take: ')),
        Spacing.h8,
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 120,
            maxWidth: 180,
          ),
          child: NumberBox<int>(
            value: context.select((ExpenseReportBloc b) => b.state.queryData.take),
            min: 1,
            mode: SpinButtonPlacementMode.none,
            clearButton: false,
            onChanged: (value) {
              if (value != null) {
                context
                    .read<ExpenseReportBloc>() //
                    .add(ExpenseReportSetTakeEvent(value));
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
    return BlocBuilder<ExpenseReportBloc, ExpenseReportState>(
      builder: (context, reportState) {
        final expenseData = reportState.queryData.expenseDataWithTake ?? [];

        return Row(
          children: [
            TextButtonFilled(
              'Generate Expense Report',
              onPressed: reportState.isGenerating
                  ? null
                  : () => unawaited(_previewReport(context, reportState, expenseData)),
            ),
          ],
        );
      },
    );
  }
}

class ExpenseReportPreview extends StatelessWidget {
  const ExpenseReportPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubheadingText('Report Preview'),
        Spacing.v12,
        _ExpenseTablePreview(),
      ],
    );
  }
}

class _ExpenseTablePreview extends StatelessWidget {
  const _ExpenseTablePreview();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ExpenseReportBloc, ExpenseReportState, List<(Order, ExpenseType)>?>(
      selector: (state) => state.queryData.expenseDataWithTake,
      builder: (context, expenseData) {
        final data = expenseData ?? [];

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
                    for (final _ExpenseColumn(:name, :flex) in expenseColumns)
                      Expanded(flex: flex, child: BodyText(name, fontWeight: FontWeight.w600)),
                  ].withSpacing(() => Spacing.h4),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final expense = data[index];

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
                        for (final _ExpenseColumn(:flex, :value) in expenseColumns)
                          Expanded(
                            flex: flex,
                            child: Text(
                              value(expense),
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
                    for (final _ExpenseColumn(:flex, :total) in expenseColumns)
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
  ExpenseReportState reportState,
  List<(Order, ExpenseType)> expenseData,
) async {
  context.read<ExpenseReportBloc>().add(const ExpenseReportSetGeneratingEvent(true));

  try {
    /// Create the PDF overlay.
    showPdfOverlay(builder: (_, overlayEntry) {
      return MultiProvider(
        providers: [
          BlocProvider.value(value: context.read<ExpenseReportBloc>()),
          BlocProvider.value(value: context.read<OrderListBloc>()),
          BlocProvider.value(value: context.read<ExpenseTypeListBloc>()),
        ],
        child: PdfOverlay(
          overlayEntry: overlayEntry,
          generatorCreator: () => _ExpenseReportPdfGenerator(
            expenseData: expenseData,
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
      context.read<ExpenseReportBloc>().add(const ExpenseReportSetGeneratingEvent(false));
    }
  }
}

const _cellPadding = pw.EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0);

// PDF generation methods
final class _ExpenseReportPdfGenerator implements PdfGenerator {
  const _ExpenseReportPdfGenerator({
    required this.expenseData,
    required this.startDate,
    required this.endDate,
  });

  final List<(Order, ExpenseType)> expenseData;
  final DateTime startDate;
  final DateTime endDate;

  @override
  String get fileName =>
      'Expense_Report_${startDate.toIso8601String().split('T').first}_to_${endDate.toIso8601String().split('T').first}.pdf';

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
            // Expense Table
            pw.Table(
              border: pw.TableBorder.symmetric(),
              columnWidths: {
                for (final (index, _ExpenseColumn(:width)) in expenseColumns.indexed) index: width,
              },
              children: [
                // Table Header
                _buildPdfExpenseHeader(),

                // Table Rows
                for (final expense in expenseData) _buildPdfExpenseItem(expense),

                _buildBottomRow(expenseData),
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
                  'Expense Report',
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

  pw.TableRow _buildPdfExpenseHeader() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      children: [
        for (final _ExpenseColumn(:name) in expenseColumns)
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

  pw.TableRow _buildPdfExpenseItem(ExpenseRecordData expense) {
    return pw.TableRow(
      children: [
        for (final _ExpenseColumn(:value) in expenseColumns)
          pw.Padding(
            padding: _cellPadding,
            child: pw.Text(
              value(expense),
              style: const pw.TextStyle(fontSize: 8),
              softWrap: false,
              overflow: pw.TextOverflow.span,
            ),
          ),
      ],
    );
  }

  pw.TableRow _buildBottomRow(List<ExpenseRecordData> expenseData) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      children: [
        for (final _ExpenseColumn(:total) in expenseColumns)
          if (total != null)
            pw.Padding(
              padding: _cellPadding,
              child: pw.Text(
                total(expenseData),
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
