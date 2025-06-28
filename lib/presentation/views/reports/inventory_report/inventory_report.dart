import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/bloc/billing/invoicelist/invoice_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_display/'
    'inventory_display_enum.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/inventory_report/'
    'inventory_report_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/inventory/product_list/product_list_bloc.dart';
import 'package:easthardware_pms/presentation/bloc/order/orderlist/order_list_bloc.dart';
import 'package:easthardware_pms/presentation/router/app_routes.dart';
import 'package:easthardware_pms/presentation/views/dashboard/cards/sales_overview.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_commons.dart';
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
import 'package:easthardware_pms/utils/number_string.dart';
import 'package:easthardware_pms/utils/typed_routes.dart';
import 'package:easthardware_pms/utils/user.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

typedef _ProductColumnRecord = (
  String name,
  int flex,
  pw.TableColumnWidth width,
  String Function(Product) value,
  Color? Function(Product)? color,
);

extension type const _ProductColumn._(_ProductColumnRecord record) {
  const _ProductColumn({
    required String name,
    int flex = 1,
    required pw.TableColumnWidth width,
    required String Function(Product) value,
    Color? Function(Product)? color,
  }) : this._(
          (
            name,
            flex,
            width,
            value,
            color,
          ),
        );

  String get name => record.$1;
  int get flex => record.$2;
  pw.TableColumnWidth get width => record.$3;
  String Function(Product) get value => record.$4;
  Color? Function(Product)? get color => record.$5;
}

final productColumns = <_ProductColumn>[
  _ProductColumn(
    name: "Product Name",
    flex: 2,
    width: const pw.IntrinsicColumnWidth(),
    value: (Product p) => p.name,
  ),
  _ProductColumn(
    name: "Category",
    width: const pw.IntrinsicColumnWidth(),
    value: (Product p) => p.categoryName ?? '-',
  ),
  _ProductColumn(
    name: "Sale Price",
    width: const pw.IntrinsicColumnWidth(),
    value: (Product p) => CurrencyFormatter.full(p.salePrice, "Php "),
  ),
  _ProductColumn(
    name: "Order Cost",
    width: const pw.IntrinsicColumnWidth(),
    value: (Product p) => CurrencyFormatter.full(p.orderCost, "Php "),
  ),
  _ProductColumn(
    name: "Critical Level",
    width: const pw.IntrinsicColumnWidth(),
    value: (Product p) => "${p.criticalLevel.toNumberString()} ${p.mainUnit}",
  ),
  _ProductColumn(
    name: "Qty on Hand",
    width: const pw.IntrinsicColumnWidth(),
    value: (Product p) => "${p.quantity.toNumberString()} ${p.mainUnit}",
  ),
];

class InventoryReportPage extends StatelessWidget {
  const InventoryReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InventoryReportBloc(
        context.read<InvoiceListBloc>().state.invoices,
        context.read<InvoiceListBloc>().state.invoiceProducts,
        context.read<OrderListBloc>().state.allOrders,
        context.read<OrderListBloc>().state.allOrderProducts,
        context.read<ProductListBloc>().state.allProducts,
      ),
      child: Builder(builder: (context) {
        return MultiBlocListener(
          listeners: [
            BlocListener<InvoiceListBloc, InvoiceListState>(
              listenWhen: (p, c) => p.invoices != c.invoices,
              listener: (context, state) {
                context
                    .read<InventoryReportBloc>()
                    .add(InventoryReportUpdateInvoicesEvent(state.invoices));
              },
            ),
            BlocListener<OrderListBloc, OrderListState>(
              listenWhen: (p, c) => p.allOrders != c.allOrders,
              listener: (context, state) {
                context
                    .read<InventoryReportBloc>()
                    .add(InventoryReportUpdateOrdersEvent(state.allOrders));
              },
            ),
            BlocListener<OrderListBloc, OrderListState>(
              listenWhen: (p, c) => p.allOrderProducts != c.allOrderProducts,
              listener: (context, state) {
                context
                    .read<InventoryReportBloc>()
                    .add(InventoryReportUpdateOrderProductsEvent(state.allOrderProducts));
              },
            ),
            BlocListener<ProductListBloc, ProductListState>(
              listenWhen: (p, c) => p.allProducts != c.allProducts,
              listener: (context, state) {
                context
                    .read<InventoryReportBloc>()
                    .add(InventoryReportUpdateProductsEvent(state.allProducts));
              },
            ),
          ],
          child: const Padding(
            padding: AppPadding.panePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InventoryReportHeader(),
                Spacing.v16,
                Expanded(
                  child: AnimatedSingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InventoryReportOptions(),
                        Spacing.v24,
                        InventoryReportPreview(),
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

class InventoryReportHeader extends StatelessWidget {
  const InventoryReportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (context.watchAccessLevel == AccessLevel.administrator) ...[
          IconButton(
            icon: const Icon(FluentIcons.home_solid),
            onPressed: () {
              /// From context.navigate(AppRoutes.admin.reports)
              context.navigate(AppRoutes.admin.reports);
            },
          ),
          Spacing.h16,
        ],
        const DisplayText('Inventory Report'),
      ],
    );
  }
}

class InventoryReportOptions extends StatelessWidget {
  const InventoryReportOptions({super.key});

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
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DateSelection(),
                    Spacing.v8,
                    _SortBy(),
                    Spacing.v8,
                    _TakeSelection(),
                  ],
                ),
              ),
              _GenerateButtons(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortBy extends StatelessWidget {
  const _SortBy();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Sort By: '),
        Spacing.h8,
        ComboBox<InventoryDisplaySortBy>(
          value: context.select((InventoryReportBloc b) => b.state.queryData.sortBy),
          items: [
            for (final value in InventoryDisplaySortBy.values)
              ComboBoxItem(
                value: value,
                child: Text(value.name),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              context //
                  .read<InventoryReportBloc>()
                  .add(InventoryReportSetSortByEvent(value));
            }
          },
        ),
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
        const Text('Take: '),
        Spacing.h8,
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 120,
            maxWidth: 180,
          ),
          child: NumberBox<int>(
            value: context.select((InventoryReportBloc b) => b.state.queryData.take),
            min: 1,
            mode: SpinButtonPlacementMode.none,
            clearButton: false,
            onChanged: (value) {
              if (value != null) {
                context
                    .read<InventoryReportBloc>() //
                    .add(InventoryReportSetTakeEvent(value));
              }
            },
          ),
        ),
      ],
    );
  }
}

class _DateSelection extends StatelessWidget {
  const _DateSelection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Report Date: '),
        Spacing.h8,
        BorderedDatePicker(
          selected: context.select((InventoryReportBloc b) => b.state.queryData.date),
          onChanged: (value) => context //
              .read<InventoryReportBloc>()
              .add(InventoryReportSetDateEvent(value)),
        ),
      ],
    );
  }
}

class _GenerateButtons extends StatelessWidget {
  const _GenerateButtons();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryReportBloc, InventoryReportState>(
      builder: (context, reportState) {
        final filteredProducts = reportState.queryData.filteredProductsWithTake ??
            context.read<ProductListBloc>().state.allProducts;

        return Row(
          children: [
            TextButtonFilled(
              'Print or Save Report',
              onPressed: reportState.isGenerating
                  ? null
                  : () => unawaited(_previewReport(context, reportState, filteredProducts)),
            ),
          ],
        );
      },
    );
  }
}

class InventoryReportPreview extends StatelessWidget {
  const InventoryReportPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubheadingText('Report Preview'),
        Spacing.v12,
        _SummarySection(),
        Spacing.v12,
        _ProductTablePreview(),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductListBloc>().state.allProducts;
    final totalProducts = products.where((p) => p.archiveStatus != 1).length;
    final lowStockCount = products.where((p) => p.isBelowCriticalLevel == true).length;
    final fastMovingCount = products.where((p) => p.isFastMovingStock == true).length;
    final deadStockCount = products.where((p) => p.isDeadStock == true).length;
    final archivedProducts = products.where((p) => p.archiveStatus == 1).length;

    return Container(
      padding: AppPadding.cardPadding,
      color: FluentTheme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Total Products',
              totalProducts.toString(),
              FluentIcons.product_list,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Low Stock Items',
              lowStockCount.toString(),
              FluentIcons.warning,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Out of Stock',
              deadStockCount.toString(),
              FluentIcons.error,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Active Products',
              fastMovingCount.toString(),
              FluentIcons.product_list,
            ),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Archived Products',
              archivedProducts.toString(),
              FluentIcons.warning,
            ),
          ),
        ].withSpacing(() => Spacing.h8),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Builder(builder: (context) {
      return Column(
        children: [
          Icon(icon, size: 32),
          Spacing.v8,
          HeadingText(value),
          Text(label, style: TextStyles.caption),
        ],
      );
    });
  }
}

class _ProductTablePreview extends StatelessWidget {
  const _ProductTablePreview();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<InventoryReportBloc, InventoryReportState, List<Product>?>(
      selector: (state) => state.queryData.filteredProductsWithTake,
      builder: (context, filteredProducts) {
        final products = filteredProducts ?? context.read<ProductListBloc>().state.allProducts;

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
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    for (final _ProductColumn(:name, :flex) in productColumns)
                      Expanded(flex: flex, child: BodyText(name, fontWeight: FontWeight.w600)),
                  ].withSpacing(() => Spacing.h4),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
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
                        for (final _ProductColumn(:flex, :value, :color) in productColumns)
                          Expanded(
                            flex: flex,
                            child: Text(
                              value(product),
                              style: TextStyles.body.copyWith(color: color?.call(product)),
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
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: productColumns.first.flex,
                        child: Text(
                          'Total',
                          style: TextStyles.body.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      for (final (index, _ProductColumn(:flex)) in productColumns.indexed)
                        if (index != 0 && index != productColumns.length - 1)
                          Expanded(
                            flex: flex,
                            child: const Text(
                              '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      Expanded(
                        flex: productColumns.last.flex,
                        child: Text(
                          '${products.fold(0.0, (sum, p) => sum + p.quantity).toNumberString()} items',
                          style: TextStyles.body,
                        ),
                      ),
                    ].withSpacing(() => Spacing.h4),
                  ),
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
  InventoryReportState reportState,
  List<Product> products,
) async {
  context.read<InventoryReportBloc>().add(const InventoryReportSetGeneratingEvent(true));

  try {
    /// Create the PDF overlay.

    showPdfOverlay(builder: (_, overlayEntry) {
      return MultiProvider(
        providers: [
          BlocProvider.value(value: context.read<InventoryReportBloc>()),
          BlocProvider.value(value: context.read<ProductListBloc>()),
        ],
        child: PdfOverlay(
          overlayEntry: overlayEntry,
          generatorCreator: () => _InventoryReportPdfGenerator(
            products: products,
            selectedDate: reportState.queryData.date ?? DateTime.now().zeroedTime(),
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
      context.read<InventoryReportBloc>().add(const InventoryReportSetGeneratingEvent(false));
    }
  }
}

const _cellPadding = pw.EdgeInsets.symmetric(horizontal: 8.0);

// PDF generation methods
final class _InventoryReportPdfGenerator with PdfCommons implements PdfGenerator {
  const _InventoryReportPdfGenerator({
    required this.products,
    required this.selectedDate,
  });

  final List<Product> products;
  final DateTime selectedDate;

  @override
  String get fileName => 'Inventory_Report_${selectedDate.toIso8601String().split('T').first}.pdf';

  @override
  Future<Uint8List> generatePdf(PdfPageFormat? format) async {
    final pdf = pw.Document();
    final logo = await rootBundle.load('assets/icons/app.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => buildPdfHeaderSingleDate(context, logo, selectedDate),
        build: (context) {
          return [
            // Summary (only on first page)
            _buildSummary(context, products),
            pw.SizedBox(height: 15),

            // Product Table
            pw.Table(
              border: pw.TableBorder.symmetric(),
              columnWidths: {
                for (final (index, _ProductColumn(:width)) in productColumns.indexed) index: width,
              },
              children: [
                // Table Header
                _buildPdfProductHeader(),

                // Table Rows
                for (final product in products) _buildPdfProductItem(product),

                _buildBottomRow(products),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSummary(pw.Context context, List<Product> products) {
    final totalProducts = products.where((p) => p.archiveStatus != 1).length;
    final lowStockCount = products.where((p) => p.isBelowCriticalLevel == true).length;
    final fastMovingCount = products.where((p) => p.isFastMovingStock == true).length;
    final deadStockCount = products.where((p) => p.isDeadStock == true).length;
    final archivedProducts = products.where((p) => p.archiveStatus == 1).length;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildPdfSummaryItem(
          'Total Products',
          totalProducts.toString(),
        ),
        _buildPdfSummaryItem(
          'Low Stock',
          lowStockCount.toString(),
        ),
        _buildPdfSummaryItem(
          'Out of Stock',
          deadStockCount.toString(),
        ),
        _buildPdfSummaryItem(
          'Fast Moving Products',
          fastMovingCount.toString(),
        ),
        _buildPdfSummaryItem(
          'Archived Products',
          archivedProducts.toString(),
        ),
      ],
    );
  }

  pw.Widget _buildPdfSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.TableRow _buildPdfProductHeader() {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      children: [
        for (final _ProductColumn(:name) in productColumns)
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

  pw.TableRow _buildPdfProductItem(Product product) {
    return pw.TableRow(
      children: [
        for (final _ProductColumn(:value, :color) in productColumns)
          if (color?.call(product)?.value case final color)
            pw.Padding(
              padding: _cellPadding,
              child: pw.Text(
                value(product),
                style: pw.TextStyle(
                  fontSize: 8,
                  color: color == null ? null : PdfColor.fromInt(color),
                ),
                softWrap: false,
                overflow: pw.TextOverflow.span,
              ),
            ),
      ],
    );
  }

  pw.TableRow _buildBottomRow(List<Product> products) {
    final totalQuantity = products.fold(0.0, (sum, p) => sum + p.quantity);

    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      children: [
        pw.Padding(
          padding: _cellPadding,
          child: pw.Text(
            'Total',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
        ),
        for (final (_) in productColumns.skip(1).take(productColumns.length - 2))
          pw.Padding(
            padding: _cellPadding,
            child: pw.Text(
              '',
              style: const pw.TextStyle(fontSize: 8),
              softWrap: false,
              overflow: pw.TextOverflow.span,
            ),
          ),
        pw.Padding(
          padding: _cellPadding,
          child: pw.Text(
            '${totalQuantity.toNumberString()} items',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ],
    );
  }
}
