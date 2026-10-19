import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';

void main() {
  test('Excel creation and reading test', () {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    // Append headers
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Amount'),
      TextCellValue('Category'),
      TextCellValue('Case'),
      TextCellValue('Court'),
      TextCellValue('Compensated'),
      TextCellValue('Notes'),
    ]);

    // Append row 1
    sheet.appendRow([
      TextCellValue('2024-10-15'),
      const DoubleCellValue(150.50),
      TextCellValue('Court Fees'),
      TextCellValue('State v. Sharma'),
      TextCellValue('High Court'),
      TextCellValue('Yes'),
      TextCellValue('Filing stamp charges'),
    ]);

    final bytes = excel.encode()!;
    final readExcel = Excel.decodeBytes(bytes);
    final readSheet = readExcel.tables[sheetName]!;

    expect(readSheet.rows.length, 2);
    final headerRow = readSheet.rows[0];
    final values = headerRow.map((cell) => cell?.value?.toString()).toList();
    expect(values, ['Date', 'Amount', 'Category', 'Case', 'Court', 'Compensated', 'Notes']);

    final dataRow = readSheet.rows[1];
    expect(dataRow[0]?.value?.toString(), '2024-10-15');
    expect(dataRow[1]?.value?.toString(), '150.5');
    expect(dataRow[2]?.value?.toString(), 'Court Fees');
    expect(dataRow[3]?.value?.toString(), 'State v. Sharma');
    expect(dataRow[4]?.value?.toString(), 'High Court');
    expect(dataRow[5]?.value?.toString(), 'Yes');
    expect(dataRow[6]?.value?.toString(), 'Filing stamp charges');
  });
}
