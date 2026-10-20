// ignore_for_file: prefer_const_constructors, avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';

void main() {
  test('Generate official sample expense template', () {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    // Header styling
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headers = [
      'Date',
      'Amount',
      'Category',
      'Compensated',
      'Case',
      'Court',
      'Notes',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

    // Sample Row 1: Uncompensated / pending (will appear on Dashboard)
    sheet.appendRow([
      TextCellValue('15/10/2024'),
      DoubleCellValue(250.00),
      TextCellValue('Court Fees'),
      TextCellValue('No'),
      TextCellValue('State v. Sharma'),
      TextCellValue('High Court of Delhi'),
      TextCellValue('Certified copy urgent fee'),
    ]);

    // Sample Row 2: Compensated / reimbursed (will appear in History as a single record)
    sheet.appendRow([
      TextCellValue('16/10/2024'),
      DoubleCellValue(420.00),
      TextCellValue('Travel & Transport'),
      TextCellValue('Yes'),
      TextCellValue('Mehta v. Union of India'),
      TextCellValue('Supreme Court of India'),
      TextCellValue('Cab to Court 2'),
    ]);

    // Sample Row 3: Printing with optional columns omitted / empty notes
    sheet.appendRow([
      TextCellValue('18/10/2024'),
      DoubleCellValue(180.00),
      TextCellValue('Printing & Stationery'),
      TextCellValue('No'),
      TextCellValue('General'),
      TextCellValue(''),
      TextCellValue(''),
    ]);

    final dir = Directory('assets/templates');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final file = File('assets/templates/expense_template.xlsx');
    file.writeAsBytesSync(excel.encode()!);
    expect(file.existsSync(), isTrue);
    print('Template created at: ${file.path} (${file.lengthSync()} bytes)');
  });
}
