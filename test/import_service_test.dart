// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:lexledger/services/import_service.dart';

void main() {
  group('ImportService Unit Tests', () {
    test('generateTemplateBytes produces valid Excel workbook with expected columns', () {
      final bytes = ImportService.generateTemplateBytes();
      expect(bytes, isNotEmpty);

      final excel = Excel.decodeBytes(bytes);
      expect(excel.tables.isNotEmpty, isTrue);

      final sheet = excel.tables[excel.getDefaultSheet()]!;
      expect(sheet.maxRows, greaterThanOrEqualTo(4));

      final headerCells = sheet.rows[0].map((c) => c?.value?.toString()).toList();
      expect(headerCells, contains('Date'));
      expect(headerCells, contains('Amount'));
      expect(headerCells, contains('Category'));
      expect(headerCells, contains('Compensated'));
      expect(headerCells, contains('Case'));
      expect(headerCells, contains('Court'));
      expect(headerCells, contains('Notes'));

      // Row 1: Uncompensated sample
      final row1 = sheet.rows[1].map((c) => c?.value?.toString()).toList();
      expect(row1[0], '15/10/2024');
      expect(row1[2], 'Court Fees');
      expect(row1[3], 'No');
      expect(row1[4], 'State v. Sharma');

      // Row 2: Compensated sample
      final row2 = sheet.rows[2].map((c) => c?.value?.toString()).toList();
      expect(row2[0], '16/10/2024');
      expect(row2[2], 'Travel & Transport');
      expect(row2[3], 'Yes');
      expect(row2[4], 'Mehta v. Union of India');

      // Row 3: Optional columns omitted
      final row3 = sheet.rows[3].map((c) => c?.value?.toString()).toList();
      expect(row3[0], '18/10/2024');
      expect(row3[2], 'Printing & Stationery');
      expect(row3[3], 'No');
    });

    test('Template contains exactly Date, Amount, Category, Compensated, Case, Court, Notes', () {
      final bytes = ImportService.generateTemplateBytes();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.getDefaultSheet()]!;
      final headers = sheet.rows[0].map((c) => c?.value?.toString()).toList();
      expect(headers, ['Date', 'Amount', 'Category', 'Compensated', 'Case', 'Court', 'Notes']);
    });
  });
}
