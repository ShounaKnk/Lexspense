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
      expect(headerCells, contains('Case'));
      expect(headerCells, contains('Court'));
      expect(headerCells, contains('Compensated'));
      expect(headerCells, contains('Notes'));

      // Row 1: Uncompensated sample
      final row1 = sheet.rows[1].map((c) => c?.value?.toString()).toList();
      expect(row1[0], '15/10/2024');
      expect(row1[2], 'Court Fees');
      expect(row1[3], 'State v. Sharma');
      expect(row1[5], 'No');

      // Row 2: Compensated sample
      final row2 = sheet.rows[2].map((c) => c?.value?.toString()).toList();
      expect(row2[0], '16/10/2024');
      expect(row2[2], 'Travel & Transport');
      expect(row2[3], 'Mehta v. Union of India');
      expect(row2[5], 'Yes');
    });
  });
}
