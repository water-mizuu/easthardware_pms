import 'dart:async';

import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/category.dart';
import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/invoice_product.dart';
import 'package:easthardware_pms/domain/models/product.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_generation.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void generateInvoicePdf(
  Invoice invoice,
  List<InvoiceProduct> invoiceProducts,
  List<Product> products,
  List<Category> categories,
) {
  showPdfOverlay(builder: (_, overlayEntry) {
    return PdfOverlay(
      overlayEntry: overlayEntry,
      generatorCreator: () => _InvoicePdfGenerator(
        invoice: invoice,
        invoiceProducts: invoiceProducts,
        products: products,
        categories: categories,
      ),
    );
  });
}

/// PDF generator for invoices
///
/// Generates a professional invoice PDF document containing:
/// - Company header with logo and invoice number
/// - Customer billing information
/// - Invoice and due dates
/// - Itemized products table with descriptions, quantities, rates, and amounts
/// - Invoice summary with subtotal, discount, and total
/// - Payment information (if applicable)
/// - Notes/memo section (if provided)
///
/// The layout follows standard invoice formatting with clear sections
/// and professional typography appropriate for business use.
final class _InvoicePdfGenerator implements PdfGenerator {
  const _InvoicePdfGenerator({
    required this.invoice,
    required this.invoiceProducts,
    required this.products,
    required this.categories,
  });

  final Invoice invoice;
  final List<InvoiceProduct> invoiceProducts;
  final List<Product> products;
  final List<Category> categories;

  @override
  String get fileName => 'Invoice_${invoice.id}_${invoice.customerName.replaceAll(' ', '_')}.pdf';

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
            _buildInvoiceDetails(),
            pw.SizedBox(height: 20),
            _buildProductsTable(),
            pw.SizedBox(height: 20),
            _buildInvoiceSummary(),
            if (invoice.memo != null && invoice.memo!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildMemoSection(),
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
                  'INVOICE',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Invoice #${invoice.id}',
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

  pw.Widget _buildInvoiceDetails() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (invoice.customerName.isNotEmpty) ...[
                pw.Text(
                  'Bill To:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  invoice.customerName,
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
              _buildDetailRow('Invoice Date:', _formatDate(invoice.invoiceDate)),
              _buildDetailRow('Due Date:', _formatDate(invoice.dueDate)),
              if (invoice.paymentDate != null)
                _buildDetailRow('Payment Date:', _formatDate(invoice.paymentDate!)),
              if (invoice.referenceNumber != null && invoice.referenceNumber!.isNotEmpty)
                _buildDetailRow('Reference:', invoice.referenceNumber!),
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
        2: pw.FlexColumnWidth(2), // Category
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
            _buildTableHeader('Category', pw.TextAlign.left),
            _buildTableHeader('Qty', pw.TextAlign.right),
            _buildTableHeader('Rate', pw.TextAlign.right),
            _buildTableHeader('Amount', pw.TextAlign.right),
          ],
        ),
        // Product rows
        for (int i = 0; i < invoiceProducts.length; i++)
          _buildProductRow(i + 1, invoiceProducts[i]),
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

  pw.TableRow _buildProductRow(int index, InvoiceProduct invoiceProduct) {
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
            invoiceProduct.productName,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Builder(builder: (context) {
            // Display the category name if available, otherwise show an empty string
            final resolvedProduct = products.firstWhere((p) => p.id == invoiceProduct.productId);

            return pw.Text(
              resolvedProduct.categoryName ?? '',
              style: const pw.TextStyle(fontSize: 9),
            );
          }),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            invoiceProduct.quantity.toString(),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            CurrencyFormatter.full(invoiceProduct.rate, 'Php '),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: pw.Text(
            CurrencyFormatter.full(invoiceProduct.amount, 'Php '),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceSummary() {
    final subtotal = invoiceProducts.fold<double>(0, (sum, product) => sum + product.amount);
    final discount = invoice.discount ?? 0.0;
    final total = invoice.amountDue;
    final amountPaid = invoice.amountPaid ?? 0.0;
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
                if (discount > 0)
                  _buildSummaryRow(
                    'Discount:',
                    invoice.discountType == DiscountType.percentage
                        ? '${discount.toStringAsFixed(2)}%'
                        : CurrencyFormatter.full(discount, 'Php '),
                  ),
                _buildSummaryRow(
                  'Total:',
                  CurrencyFormatter.full(total, 'Php '),
                  isTotal: true,
                ),
                if (amountPaid > 0) ...[
                  _buildSummaryRow(
                    'Amount Paid:',
                    CurrencyFormatter.full(amountPaid, 'Php '),
                  ),
                  _buildSummaryRow(
                    'Balance:',
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

  pw.Widget _buildMemoSection() {
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
            'Notes:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            invoice.memo!,
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
