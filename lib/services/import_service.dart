import 'dart:io';
import 'package:excel/excel.dart';
import '../core/database/database_helper.dart';
import '../data/models/expense.dart';
import '../data/models/client_matter.dart';
import '../data/models/expense_category.dart';
import '../data/models/court_forum.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/court_forum_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/matter_repository.dart';

/// Summary of an import operation.
class ImportResult {
  final int totalRows;
  final int imported;
  final int skipped;
  final List<String> warnings;

  const ImportResult({
    required this.totalRows,
    required this.imported,
    required this.skipped,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
}

/// Service that parses Excel workbooks and bulk-imports expenses into the database.
class ImportService {
  final DatabaseHelper _dbHelper;
  final MatterRepository _matterRepo;
  final CategoryRepository _categoryRepo;
  final CourtForumRepository _forumRepo;
  final ExpenseRepository _expenseRepo;

  ImportService({
    required DatabaseHelper dbHelper,
    required MatterRepository matterRepo,
    required CategoryRepository categoryRepo,
    required CourtForumRepository forumRepo,
    required ExpenseRepository expenseRepo,
  })  : _dbHelper = dbHelper,
        _matterRepo = matterRepo,
        _categoryRepo = categoryRepo,
        _forumRepo = forumRepo,
        _expenseRepo = expenseRepo;

  /// Parse and import an Excel file from disk.
  Future<ImportResult> importFromFile(
    File file, {
    void Function(int current, int total)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    return importFromBytes(bytes, onProgress: onProgress);
  }

  /// Parse and import from raw bytes (supports .xlsx and .xls).
  Future<ImportResult> importFromBytes(
    List<int> bytes, {
    void Function(int current, int total)? onProgress,
  }) async {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw const FormatException('The selected Excel file contains no sheets.');
    }

    // Use the first non-empty sheet
    Sheet? targetSheet;
    for (final sheet in excel.tables.values) {
      if (sheet.maxRows > 0) {
        targetSheet = sheet;
        break;
      }
    }

    if (targetSheet == null || targetSheet.maxRows == 0) {
      throw const FormatException('The spreadsheet is empty.');
    }

    final rows = targetSheet.rows;
    if (rows.isEmpty) {
      throw const FormatException('No rows found in the spreadsheet.');
    }

    // 1. Locate and map header row
    final headerRow = rows[0];
    final colMap = _mapHeaders(headerRow);

    // Validate mandatory columns
    final missing = <String>[];
    if (!colMap.containsKey('date')) missing.add('Date');
    if (!colMap.containsKey('amount')) missing.add('Amount');
    if (!colMap.containsKey('category')) missing.add('Category');
    if (!colMap.containsKey('case')) missing.add('Case / Matter');

    if (missing.isNotEmpty) {
      throw FormatException(
        'Missing required header column(s): ${missing.join(', ')}.\n\n'
        'Please ensure row 1 contains: Date, Amount, Category, Case (and optionally Court, Compensated, Notes).',
      );
    }

    final db = await _dbHelper.database;

    // 2. Pre-load existing lookups for O(1) resolution (NOCASE match)
    final existingCategories = await _categoryRepo.getAll();
    final categoryMap = <String, int>{
      for (final c in existingCategories) c.name.trim().toLowerCase(): c.id!,
    };

    final existingForums = await _forumRepo.getAll();
    final forumMap = <String, int>{
      for (final f in existingForums) f.name.trim().toLowerCase(): f.id!,
    };

    final existingMatters = await _matterRepo.getAll();
    final matterMap = <String, int>{
      for (final m in existingMatters) m.caseTitle.trim().toLowerCase(): m.id!,
    };

    int importedCount = 0;
    int skippedCount = 0;
    final warnings = <String>[];
    final totalDataRows = rows.length - 1;

    // 3. Process data rows
    for (int i = 1; i < rows.length; i++) {
      final rowNumber = i + 1; // 1-indexed for user-friendly error messages
      final row = rows[i];

      onProgress?.call(i, totalDataRows);

      // Check if entire row is empty
      if (_isRowEmpty(row)) {
        continue;
      }

      // Extract raw cell values
      final rawDate = _getCellValue(row, colMap['date']);
      final rawAmount = _getCellValue(row, colMap['amount']);
      final rawCategory = _getCellValue(row, colMap['category']);
      final rawCase = _getCellValue(row, colMap['case']);
      final rawCourt = _getCellValue(row, colMap['court']);
      final rawCompensated = _getCellValue(row, colMap['compensated']);
      final rawNotes = _getCellValue(row, colMap['notes']);

      // 3a. Validate Date
      final parsedDate = _parseDate(rawDate);
      if (parsedDate == null) {
        skippedCount++;
        warnings.add('Row $rowNumber: Invalid or missing date "${rawDate ?? ''}". Expected DD/MM/YYYY or YYYY-MM-DD.');
        continue;
      }

      // 3b. Validate Amount
      final parsedPaise = _parsePaise(rawAmount);
      if (parsedPaise == null || parsedPaise <= 0) {
        skippedCount++;
        warnings.add('Row $rowNumber: Invalid amount "${rawAmount ?? ''}". Must be a positive number.');
        continue;
      }

      // 3c. Validate Case
      final caseTitle = rawCase?.toString().trim();
      if (caseTitle == null || caseTitle.isEmpty) {
        skippedCount++;
        warnings.add('Row $rowNumber: Case / Matter title is empty.');
        continue;
      }

      // 3d. Validate Category
      final categoryName = rawCategory?.toString().trim();
      if (categoryName == null || categoryName.isEmpty) {
        skippedCount++;
        warnings.add('Row $rowNumber: Category name is empty.');
        continue;
      }

      final notes = rawNotes?.toString().trim();
      final isCompensated = _parseCompensated(rawCompensated);

      try {
        // 4. Resolve or create Forum (if given)
        int? forumId;
        final courtName = rawCourt?.toString().trim();
        if (courtName != null && courtName.isNotEmpty) {
          final forumKey = courtName.toLowerCase();
          if (forumMap.containsKey(forumKey)) {
            forumId = forumMap[forumKey];
          } else {
            // Auto-create court forum
            final newForum = CourtForum(name: courtName);
            final newId = await _forumRepo.insert(newForum);
            forumMap[forumKey] = newId;
            forumId = newId;
          }
        }

        // 5. Resolve or create Matter
        final matterKey = caseTitle.toLowerCase();
        int matterId;
        if (matterMap.containsKey(matterKey)) {
          matterId = matterMap[matterKey]!;
        } else {
          // Auto-create client matter
          final newMatter = ClientMatter(
            caseTitle: caseTitle,
            forumId: forumId,
          );
          final newId = await _matterRepo.insert(newMatter);
          matterMap[matterKey] = newId;
          matterId = newId;
        }

        // 6. Resolve or create Category
        final catKey = categoryName.toLowerCase();
        int categoryId;
        if (categoryMap.containsKey(catKey)) {
          categoryId = categoryMap[catKey]!;
        } else {
          // Auto-create category with generic icon
          final newCat = ExpenseCategory(
            name: categoryName,
            icon: 'more_horiz',
          );
          final newId = await _categoryRepo.insert(newCat);
          categoryMap[catKey] = newId;
          categoryId = newId;
        }

        // 7. Duplicate Detection: Check if identical expense already exists
        final existingExpense = await db.query(
          'expenses',
          columns: ['id'],
          where: 'expense_date = ? AND amount_paise = ? AND matter_id = ? AND category_id = ?',
          whereArgs: [parsedDate, parsedPaise, matterId, categoryId],
          limit: 1,
        );

        if (existingExpense.isNotEmpty) {
          skippedCount++;
          final amountRupees = (parsedPaise / 100.0).toStringAsFixed(2);
          warnings.add('Row $rowNumber: Skipped duplicate (₹$amountRupees on $parsedDate for "$caseTitle").');
          continue;
        }

        // 8. Handle Compensated status
        int? reimbursementId;
        if (isCompensated) {
          // Create a single Reimbursement record in history
          reimbursementId = await db.insert('reimbursements', {
            'total_amount_paise': parsedPaise,
            'date_paid': parsedDate,
            'notes': (notes != null && notes.isNotEmpty)
                ? 'Imported reimbursement: $notes'
                : 'Imported reimbursement',
          });
        }

        // 9. Insert Expense
        final expense = Expense(
          matterId: matterId,
          categoryId: categoryId,
          reimbursementId: reimbursementId,
          amountPaise: parsedPaise,
          expenseDate: parsedDate,
          notes: notes,
        );

        await _expenseRepo.insertExpense(expense);
        importedCount++;
      } catch (e) {
        skippedCount++;
        warnings.add('Row $rowNumber: Database insert error ($e).');
      }
    }

    return ImportResult(
      totalRows: totalDataRows,
      imported: importedCount,
      skipped: skippedCount,
      warnings: warnings,
    );
  }

  /// Maps header cells to standardized column keys.
  Map<String, int> _mapHeaders(List<Data?> headerRow) {
    final map = <String, int>{};
    for (int col = 0; col < headerRow.length; col++) {
      final cellVal = headerRow[col]?.value?.toString().trim().toLowerCase();
      if (cellVal == null || cellVal.isEmpty) continue;

      if (_isHeaderMatch(cellVal, ['date', 'expense date', 'expensedate', 'dated'])) {
        map['date'] = col;
      } else if (_isHeaderMatch(cellVal, ['amount', 'amount (rs)', 'amount (inr)', 'amount(rs)', 'cost', 'price', 'amt'])) {
        map['amount'] = col;
      } else if (_isHeaderMatch(cellVal, ['category', 'expense category', 'expense_category', 'cat', 'type'])) {
        map['category'] = col;
      } else if (_isHeaderMatch(cellVal, ['case', 'matter', 'case title', 'case name', 'client matter', 'client', 'case / matter'])) {
        map['case'] = col;
      } else if (_isHeaderMatch(cellVal, ['court', 'forum', 'court/forum', 'court / forum', 'tribunal', 'court forum'])) {
        map['court'] = col;
      } else if (_isHeaderMatch(cellVal, ['compensated', 'reimbursed', 'is compensated', 'is_compensated', 'status', 'paid', 'is paid'])) {
        map['compensated'] = col;
      } else if (_isHeaderMatch(cellVal, ['notes', 'note', 'remark', 'remarks', 'description', 'comment'])) {
        map['notes'] = col;
      }
    }
    return map;
  }

  bool _isHeaderMatch(String text, List<String> candidates) {
    return candidates.contains(text);
  }

  dynamic _getCellValue(List<Data?> row, int? colIndex) {
    if (colIndex == null || colIndex >= row.length) return null;
    return row[colIndex]?.value;
  }

  bool _isRowEmpty(List<Data?> row) {
    for (final cell in row) {
      if (cell?.value != null && cell!.value.toString().trim().isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  /// Parse various date representations into 'YYYY-MM-DD'.
  String? _parseDate(dynamic raw) {
    if (raw == null) return null;

    if (raw is DateTimeCellValue) {
      final dt = raw.asDateTimeUtc();
      return _formatIsoDate(dt.year, dt.month, dt.day);
    }

    if (raw is DateCellValue) {
      return _formatIsoDate(raw.year, raw.month, raw.day);
    }

    final str = raw.toString().trim();
    if (str.isEmpty) return null;

    // Check ISO: YYYY-MM-DD
    final isoMatch = RegExp(r'^(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})$').firstMatch(str);
    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);
      return _formatIsoDate(y, m, d);
    }

    // Check DD/MM/YYYY or DD-MM-YYYY
    final dmyMatch = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})$').firstMatch(str);
    if (dmyMatch != null) {
      final d = int.parse(dmyMatch.group(1)!);
      final m = int.parse(dmyMatch.group(2)!);
      final y = int.parse(dmyMatch.group(3)!);
      return _formatIsoDate(y, m, d);
    }

    // Standard DateTime parse attempt
    try {
      final dt = DateTime.parse(str);
      return _formatIsoDate(dt.year, dt.month, dt.day);
    } catch (_) {}

    // Numeric Excel serial date fallback (e.g. 45214)
    final numVal = double.tryParse(str);
    if (numVal != null && numVal > 30000 && numVal < 70000) {
      final dt = DateTime(1899, 12, 30).add(Duration(days: numVal.floor()));
      return _formatIsoDate(dt.year, dt.month, dt.day);
    }

    return null;
  }

  String _formatIsoDate(int year, int month, int day) {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parses monetary string into integer paise.
  int? _parsePaise(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim().replaceAll(RegExp(r'[₹,\s]'), '');
    final d = double.tryParse(str);
    if (d == null || d <= 0) return null;
    return (d * 100).round();
  }

  /// Returns true if the cell value indicates compensated / reimbursed.
  bool _parseCompensated(dynamic raw) {
    if (raw == null) return false;
    final str = raw.toString().trim().toLowerCase();
    return str == 'yes' ||
        str == 'y' ||
        str == 'true' ||
        str == '1' ||
        str == 'paid' ||
        str == 'compensated' ||
        str == 'settled';
  }

  /// Generate sample Excel workbook bytes for download/export.
  static List<int> generateTemplateBytes() {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headers = [
      'Date',
      'Amount',
      'Category',
      'Case',
      'Court',
      'Compensated',
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
      const DoubleCellValue(250.00),
      TextCellValue('Court Fees'),
      TextCellValue('State v. Sharma'),
      TextCellValue('High Court of Delhi'),
      TextCellValue('No'),
      TextCellValue('Certified copy urgent fee'),
    ]);

    // Sample Row 2: Compensated / reimbursed (will appear in History as a single record)
    sheet.appendRow([
      TextCellValue('16/10/2024'),
      const DoubleCellValue(420.00),
      TextCellValue('Travel & Transport'),
      TextCellValue('Mehta v. Union of India'),
      TextCellValue('Supreme Court of India'),
      TextCellValue('Yes'),
      TextCellValue('Cab to Court 2'),
    ]);

    // Sample Row 3: Printing
    sheet.appendRow([
      TextCellValue('18/10/2024'),
      const DoubleCellValue(180.00),
      TextCellValue('Printing & Stationery'),
      TextCellValue('State v. Sharma'),
      TextCellValue('High Court of Delhi'),
      TextCellValue('No'),
      TextCellValue('Paperbook printouts 60 pages'),
    ]);

    return excel.encode()!;
  }
}
