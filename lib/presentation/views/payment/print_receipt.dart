import 'dart:async';
import 'dart:math';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/payment.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_commons.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_generation.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void generateReceiptPdf(
  Payment payment,
  Invoice invoice,
  PaymentMethod paymentMethod,
  List<InvoiceProduct> invoiceProducts,
) {
  showPdfOverlay(builder: (_, overlayEntry) {
    return PdfOverlay(
      overlayEntry: overlayEntry,
      generatorCreator: () => _ReceiptPdfGenerator(
        payment: payment,
        invoice: invoice,
        paymentMethod: paymentMethod,
        invoiceProducts: invoiceProducts,
      ),
    );
  });
}

/// PDF generator for payment receipts
///
/// Generates a professional receipt PDF document containing:
/// - Company header with logo and receipt number
/// - Customer information (bill to)
/// - Payment method information
/// - Products/services table
/// - Payment summary with subtotal, discount, and total
///
/// The layout follows standard receipt formatting similar to invoice
/// and professional typography appropriate for business use.
final class _ReceiptPdfGenerator with PdfCommons implements PdfGenerator {
  const _ReceiptPdfGenerator({
    required this.payment,
    required this.invoice,
    required this.paymentMethod,
    required this.invoiceProducts,
  });

  final Payment payment;
  final Invoice invoice;
  final PaymentMethod paymentMethod;
  final List<InvoiceProduct> invoiceProducts;

  @override
  String get fileName => 'Receipt_${payment.id}_${invoice.customerName.replaceAll(' ', '_')}.pdf';

  @override
  Future<Uint8List> generatePdf(PdfPageFormat? format) async {
    final pdf = pw.Document();
    final logo = await rootBundle.load('assets/icons/app.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildReceiptHeader(context, logo),
        build: (context) {
          return [
            _buildReceiptDetails(),
            pw.SizedBox(height: 20),
            _buildPaymentMethod(),
            pw.SizedBox(height: 20),
            _buildProductsTable(),
            pw.SizedBox(height: 20),
            _buildReceiptSummary(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildReceiptHeader(pw.Context context, ByteData logo) {
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
                  'SALES RECEIPT',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (payment.id != null)
                  pw.Text(
                    'SALES # ${payment.id}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  )
                else
                  pw.Text(
                    ' ',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                //
                pw.SizedBox(height: 4),
                pw.Text(
                  'DATE ${_formatDate(payment.paymentDate)}',
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

  pw.Widget _buildReceiptDetails() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILL TO',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                invoice.customerName,
                style: const pw.TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        pw.Spacer(),
      ],
    );
  }

  pw.Widget _buildPaymentMethod() {
    return pw.Row(
      children: [
        pw.Text(
          'Payment Method',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(width: 20),
        pw.Text(
          paymentMethod.name,
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildProductsTable() {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(2), // Service
        1: pw.FixedColumnWidth(60), // Qty
        2: pw.FixedColumnWidth(120), // Rate
        3: pw.FixedColumnWidth(120), // Amount
      },
      children: [
        // Header row with blue background
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _buildTableHeader('Product', pw.TextAlign.left),
            _buildTableHeader('Quantity', pw.TextAlign.right),
            _buildTableHeader('Rate', pw.TextAlign.right),
            _buildTableHeader('Amount', pw.TextAlign.right),
          ],
        ),
        // Product rows
        for (int i = 0; i < invoiceProducts.length; i++) _buildProductRow(invoiceProducts[i]),
      ],
    );
  }

  static const pw.EdgeInsets _tablePadding = pw.EdgeInsets.symmetric(
    vertical: 2.0,
    horizontal: 4.0,
  );

  pw.Widget _buildTableHeader(String text, pw.TextAlign align) {
    return pw.Padding(
      padding: _tablePadding,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        textAlign: align,
      ),
    );
  }

  pw.TableRow _buildProductRow(InvoiceProduct invoiceProduct) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: _tablePadding,
          child: pw.Text(
            invoiceProduct.productName,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        pw.Padding(
          padding: _tablePadding,
          child: pw.Text(
            invoiceProduct.quantity.toString(),
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.Padding(
          padding: _tablePadding,
          child: pw.Text(
            _formatCurrency(invoiceProduct.rate),
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.Padding(
          padding: _tablePadding,
          child: pw.Text(
            _formatCurrency(invoiceProduct.amount),
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  // pw.Widget _buildInvoiceSummary() {
  //   final subtotal = invoiceProducts.fold<double>(0, (sum, product) => sum + product.amount);
  //   final discount = invoice.discount ?? 0.0;
  //   final total = invoice.amountDue;
  //   final amountPaid = invoice.amountPaid ?? 0.0;
  //   final balance = total - amountPaid;

  //   return pw.Row(
  //     children: [
  //       pw.Expanded(flex: 2, child: pw.Container()),
  //       pw.Expanded(
  //         child: pw.Container(
  //           child: pw.Column(
  //             children: [
  //               _buildSummaryRow(
  //                 'Subtotal:',
  //                 CurrencyFormatter.full(subtotal, 'Php '),
  //               ),
  //               if (discount > 0)
  //                 _buildSummaryRow(
  //                   'Discount:',
  //                   invoice.discountType == DiscountType.percentage
  //                       ? '${discount.toStringAsFixed(2)}%'
  //                       : CurrencyFormatter.full(discount, 'Php '),
  //                 ),
  //               _buildSummaryRow(
  //                 'Total:',
  //                 CurrencyFormatter.full(total, 'Php '),
  //                 isTotal: true,
  //               ),
  //               if (amountPaid > 0) ...[
  //                 _buildSummaryRow(
  //                   'Amount Paid:',
  //                   CurrencyFormatter.full(amountPaid, 'Php '),
  //                 ),
  //                 _buildSummaryRow(
  //                   'Balance:',
  //                   CurrencyFormatter.full(balance, 'Php '),
  //                   isTotal: true,
  //                 ),
  //               ],
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  pw.Widget _buildReceiptSummary() {
    final subtotal = invoiceProducts.fold<double>(0, (sum, product) => sum + product.amount);
    final discount = invoice.discount ?? 0.0;
    final discountAmount = invoice.discountType?.index == 0 // percentage
        ? subtotal * (discount / 100)
        : discount;
    final total = subtotal - discountAmount;
    final remainingBalance = max(0.0, total - payment.amount);
    final change = max(0.0, payment.amount - total);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Thank you for your business and have a great day!',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildSummaryRow('SUBTOTAL', _formatCurrency(subtotal)),
                  if (discountAmount > 0)
                    _buildSummaryRow(
                      'DISCOUNT ${invoice.discountType?.index == 0 ? '${discount.toStringAsFixed(0)}%' : ''}',
                      _formatCurrency(discountAmount),
                    ),
                  _buildSummaryRow('TOTAL', _formatCurrency(total)),
                  _buildSummarySeparator(),
                  _buildSummaryRow('AMOUNT PAID', _formatCurrency(payment.amount)),
                  _buildSummaryRow(
                    'BALANCE DUE',
                    _formatCurrency(remainingBalance),
                    isBalance: true,
                  ),
                  if (change > 0.0)
                    _buildSummaryRow(
                      'CHANGE',
                      _formatCurrency(change),
                      isBalance: true,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySeparator() {
    return pw.SizedBox(
      width: 240,
      child: pw.Divider(
        thickness: 1,
        color: PdfColors.black,
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, {bool isBalance = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: isBalance ? 14 : 11,
                fontWeight: isBalance ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: isBalance ? 14 : 11,
                fontWeight: isBalance ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatQuantity(int quantity) {
    return quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toStringAsFixed(2);
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.full(amount, 'Php ');
  }
}
