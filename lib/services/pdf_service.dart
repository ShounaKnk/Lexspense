import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/utils/currency_utils.dart';
import '../data/models/expense_view.dart';
import '../data/models/receipt_image.dart';
import '../data/models/reimbursement.dart';
import 'receipt_storage_service.dart';

/// Professional PDF voucher generation for legal expense reimbursements.
class PdfService {
  final ReceiptStorageService _receiptStorage;

  PdfService(this._receiptStorage);

  /// Generates the reimbursement voucher PDF with optional receipt attachments
  /// and opens the native system share/print dialog.
  Future<void> generateAndShareVoucher({
    required Reimbursement reimbursement,
    required List<ExpenseView> expenses,
    required Map<int, List<ReceiptImage>> receiptsByExpense,
    String lawyerName = 'Advocate',
    String firmName = 'Chambers of Law',
  }) async {
    final pdf = pw.Document();

    // 1. Voucher Sheet Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        firmName.isNotEmpty ? firmName.toUpperCase() : 'LEGAL CHAMBERS',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Counsel: $lawyerName',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green900,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'REIMBURSEMENT VOUCHER',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Voucher #: RV-${reimbursement.id.toString().padLeft(4, '0')}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'Settlement Date: ${reimbursement.datePaid}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              pw.SizedBox(height: 14),

              // Title
              pw.Text(
                'Itemized Out-of-Pocket Legal Expenses',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              // Expense Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2.5),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2.2),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell('#', isHeader: true, align: pw.TextAlign.center),
                      _cell('Case / Client Matter', isHeader: true),
                      _cell('Category', isHeader: true),
                      _cell('Date', isHeader: true),
                      _cell('Amount', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Rows
                  ...expenses.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final exp = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        _cell('$idx', align: pw.TextAlign.center),
                        _cell(
                          exp.matterTitle,
                          subtitle: exp.expense.notes != null && exp.expense.notes!.isNotEmpty
                              ? 'Note: ${exp.expense.notes}'
                              : null,
                        ),
                        _cell(exp.categoryName),
                        _cell(exp.expense.expenseDate),
                        _cell(
                          CurrencyUtils.formatForPdf(exp.expense.amountPaise),
                          align: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }),
                  // Total Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _cell(''),
                      _cell('TOTAL SETTLED', isHeader: true),
                      _cell(''),
                      _cell(''),
                      _cell(
                        CurrencyUtils.formatForPdf(reimbursement.totalAmountPaise),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),

              if (reimbursement.notes != null && reimbursement.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 14),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Batch Note: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          reimbursement.notes!,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              pw.Spacer(),

              // Signature section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 160, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Claimant Signature ($lawyerName)',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(width: 160, height: 1, color: PdfColors.black),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Senior Counsel / Approved By',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Generated securely & offline by Lexspense',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 2. Receipt Pages (if any receipt files exist)
    for (final exp in expenses) {
      final receipts = receiptsByExpense[exp.expense.id] ?? [];
      for (final receipt in receipts) {
        try {
          final file = await _receiptStorage.getReceiptFile(receipt.fileName);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final image = pw.MemoryImage(bytes);

            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                margin: const pw.EdgeInsets.all(36),
                build: (context) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Receipt Attachment: ${exp.matterTitle}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Category: ${exp.categoryName}  |  Date: ${exp.expense.expenseDate}  |  Amount: ${CurrencyUtils.formatForPdf(exp.expense.amountPaise)}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 12),
                      pw.Expanded(
                        child: pw.Center(
                          child: pw.Image(image, fit: pw.BoxFit.contain),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'File: ${receipt.fileName}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                      ),
                    ],
                  );
                },
              ),
            );
          }
        } catch (_) {
          // Continue if an image file fails to decode
        }
      }
    }

    // Save and Share / Print
    final bytes = await pdf.save();
    final fileName = 'Lexspense_Voucher_${reimbursement.id}_${reimbursement.datePaid}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    String? subtitle,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Column(
        crossAxisAlignment: align == pw.TextAlign.right
            ? pw.CrossAxisAlignment.end
            : align == pw.TextAlign.center
                ? pw.CrossAxisAlignment.center
                : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            text,
            textAlign: align,
            style: pw.TextStyle(
              fontSize: isHeader ? 9 : 8.5,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHeader ? PdfColors.black : PdfColors.grey900,
            ),
          ),
          if (subtitle != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              textAlign: align,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }
}
