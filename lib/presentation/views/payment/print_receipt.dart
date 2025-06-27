import 'dart:async';

import 'package:easthardware_pms/domain/models/invoice.dart';
import 'package:easthardware_pms/domain/models/payment.dart';
import 'package:easthardware_pms/domain/models/payment_method.dart';
import 'package:easthardware_pms/presentation/views/reports/pdf_helpers/pdf_generation.dart';
import 'package:easthardware_pms/presentation/widgets/helper/currency_formatter.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void generateReceiptPdf(
  Payment payment,
  Invoice invoice,
  PaymentMethod paymentMethod,
) {
  showPdfOverlay(builder: (_, overlayEntry) {
    return PdfOverlay(
      overlayEntry: overlayEntry,
      generatorCreator: () => _ReceiptPdfGenerator(
        payment: payment,
        invoice: invoice,
        paymentMethod: paymentMethod,
      ),
    );
  });
}

/// PDF generator for payment receipts
///
/// Generates a professional receipt PDF document containing:
/// - Company header with logo and receipt number
/// - Customer information
/// - Payment details including amount received
/// - Payment method and reference number
/// - Invoice information that was paid
/// - Receipt date and transaction details
///
/// The layout follows standard receipt formatting with clear sections
/// and professional typography appropriate for business use.
final class _ReceiptPdfGenerator implements PdfGenerator {
  const _ReceiptPdfGenerator({
    required this.payment,
    required this.invoice,
    required this.paymentMethod,
  });

  final Payment payment;
  final Invoice invoice;
  final PaymentMethod paymentMethod;

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
        header: (context) => _buildPdfHeader(context, logo),
        build: (context) {
          return [
            _buildReceiptDetails(),
            pw.SizedBox(height: 20),
            _buildPaymentInformation(),
            pw.SizedBox(height: 20),
            _buildInvoiceInformation(),
            pw.SizedBox(height: 30),
            _buildReceiptSummary(),
            pw.SizedBox(height: 20),
            _buildFooter(),
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
                  'PAYMENT RECEIPT',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Receipt #${payment.id}',
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
                'Received From:',
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
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildDetailRow('Payment Date:', _formatDate(payment.paymentDate)),
              _buildDetailRow('Receipt Date:', _formatDate(DateTime.now())),
              _buildDetailRow('Reference:', payment.referenceNumber),
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

  pw.Widget _buildPaymentInformation() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Payment Information',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Amount Received:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
              ),
              pw.Text(
                CurrencyFormatter.full(payment.amount, 'Php '),
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Payment Method:',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                paymentMethod.name,
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Reference Number:',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                payment.referenceNumber,
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceInformation() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Invoice Information',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Invoice Number:',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                '#${invoice.id}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Invoice Date:',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                _formatDate(invoice.invoiceDate),
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Due Date:',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                _formatDate(invoice.dueDate),
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Invoice Total:',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                CurrencyFormatter.full(invoice.amountDue, 'Php '),
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReceiptSummary() {
    final totalPaid = invoice.amountPaid ?? 0.0;
    final balance = invoice.amountDue - totalPaid;

    return pw.Row(
      children: [
        pw.Expanded(flex: 2, child: pw.Container()),
        pw.Expanded(
          child: pw.Container(
            child: pw.Column(
              children: [
                _buildSummaryRow(
                  'Total Invoice Amount:',
                  CurrencyFormatter.full(invoice.amountDue, 'Php '),
                ),
                _buildSummaryRow(
                  'Previous Payments:',
                  CurrencyFormatter.full(totalPaid - payment.amount, 'Php '),
                ),
                _buildSummaryRow(
                  'This Payment:',
                  CurrencyFormatter.full(payment.amount, 'Php '),
                  isTotal: true,
                ),
                _buildSummaryRow(
                  'Total Paid:',
                  CurrencyFormatter.full(totalPaid, 'Php '),
                ),
                _buildSummaryRow(
                  'Balance Due:',
                  CurrencyFormatter.full(balance, 'Php '),
                  isTotal: balance > 0,
                ),
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

  pw.Widget _buildFooter() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your payment!',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'This receipt serves as proof of payment for the above referenced invoice.',
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
