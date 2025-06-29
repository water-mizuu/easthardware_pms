import 'dart:async';

import 'package:easthardware_pms/domain/models/expense_type.dart';
import 'package:easthardware_pms/domain/models/order.dart';
import 'package:easthardware_pms/domain/models/order_item.dart';
import 'package:easthardware_pms/domain/models/order_product.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_generation.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:easthardware_pms/utils/num_iterable_extension.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void generateOrderPdf(
  Order order,
  ExpenseType expenseType,
  List<OrderProduct> orderProducts,
  List<OrderItem> items,
) {
  showPdfOverlay(builder: (_, overlayEntry) {
    return PdfOverlay(
      overlayEntry: overlayEntry,
      generatorCreator: () => _OrderPdfGenerator(
        order: order,
        expenseType: expenseType,
        orderProducts: orderProducts,
        orderItems: items,
      ),
    );
  });
}

/// PDF generator for orders
///
/// Generates a professional order PDF document containing:
/// - Company header with logo and order number
/// - Customer information
/// - Order date and expected delivery date
/// - Itemized products table with descriptions, quantities, rates, and amounts
/// - Order summary with subtotal, discount, and total
/// - Payment information (if applicable)
/// - Notes/memo section (if provided)
///
/// The layout follows standard order formatting with clear sections
/// and professional typography appropriate for business use.
final class _OrderPdfGenerator implements PdfGenerator {
  const _OrderPdfGenerator({
    required this.order,
    required this.expenseType,
    required this.orderProducts,
    required this.orderItems,
  });

  final Order order;
  final ExpenseType expenseType;
  final List<OrderProduct> orderProducts;
  final List<OrderItem> orderItems;

  @override
  String get fileName => 'Order_${order.id}.pdf';

  @override
  Future<Uint8List> generatePdf(PdfPageFormat? format) async {
    final pdf = pw.Document();
    final logo = await rootBundle.load('assets/icons/app.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildPdfHeader(context, logo),
        build: (context) {
          return [
            _buildOrderDetails(),
            pw.SizedBox(height: 20),
            _buildProductsTable(),
            pw.SizedBox(height: 20),
            _buildOrderSummary(),
            if (order.memo != null && order.memo!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildMemo(),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfHeader(pw.Context context, ByteData logo) {
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
                pw.SizedBox(height: 16),
                pw.Text(
                  'ORDER',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Order #${order.id}',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 16),
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

  pw.Widget _buildOrderDetails() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (order.payeeName.isNotEmpty) ...[
                pw.Text(
                  'Vendor:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  order.payeeName,
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ]
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildDetailRow('Order Date:', _formatDate(order.orderDate)),
              _buildDetailRow('Creation Date:', _formatDate(order.creationDate)),
              if (order.paymentDate != null)
                _buildDetailRow('Payment Date:', _formatDate(order.paymentDate!)),
              if (order.referenceNumber != null && order.referenceNumber!.isNotEmpty)
                _buildDetailRow('Reference:', order.referenceNumber!),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProductsTable() {
    return pw.Table(
      // border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(30), // #
        1: pw.FlexColumnWidth(3), // Product
        2: pw.FlexColumnWidth(2), // Description
        3: pw.FlexColumnWidth(1), // Qty
        4: pw.FlexColumnWidth(1.5), // Rate
        5: pw.FlexColumnWidth(1.5), // Amount
      },
      children: [
        // Header row
        pw.TableRow(
          children: [
            _buildTableHeader('#', pw.TextAlign.center),
            _buildTableHeader('Product', pw.TextAlign.left),
            _buildTableHeader('Qty', pw.TextAlign.right),
            _buildTableHeader('Rate', pw.TextAlign.right),
            _buildTableHeader('Amount', pw.TextAlign.right),
          ],
        ),
        // Product rows
        for (int i = 0; i < orderProducts.length; i++) _buildProductRow(i + 1, orderProducts[i]),
        // Item rows
        for (int i = 0; i < orderItems.length; i++) _buildItemRow(i + 1, orderItems[i]),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text, pw.TextAlign align) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        textAlign: align,
      ),
    );
  }

  pw.TableRow _buildProductRow(int index, OrderProduct orderProduct) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            index.toString(),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            orderProduct.productName,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            orderProduct.quantity.toString(),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            CurrencyFormatter.full(orderProduct.rate, 'Php '),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            CurrencyFormatter.full(orderProduct.amount, 'Php '),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  pw.TableRow _buildItemRow(int index, OrderItem orderItem) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            index.toString(),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            orderItem.name,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            orderItem.quantity.toString(),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            CurrencyFormatter.full(orderItem.rate, 'Php '),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            CurrencyFormatter.full(orderItem.amount, 'Php '),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildOrderSummary() {
    final subtotal = (orderItems.map((i) => i.amount)) //
        .followedBy(orderProducts.map((p) => p.amount))
        .sum();
    final total = order.amountDue;
    final amountPaid = order.amountPaid ?? 0.0;
    final balance = total - amountPaid;

    return pw.Row(
      children: [
        pw.Expanded(flex: 2, child: pw.Container()),
        pw.Expanded(
          child: pw.Container(
            child: pw.Column(
              children: [
                _buildSummaryRow(
                  'Subtotal:',
                  CurrencyFormatter.full(subtotal, 'Php '),
                ),
                _buildSummaryRow(
                  'Order Total:',
                  CurrencyFormatter.full(total, 'Php '),
                  isTotal: true,
                ),
                if (amountPaid > 0) ...[
                  _buildSummaryRow(
                    'Down Payment:',
                    CurrencyFormatter.full(amountPaid, 'Php '),
                  ),
                  _buildSummaryRow(
                    'Balance Due:',
                    CurrencyFormatter.full(balance, 'Php '),
                    isTotal: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: isTotal
          ? const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 1)),
              color: PdfColors.grey100,
            )
          : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 11 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 11 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMemo() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Special Instructions:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            order.memo!,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
