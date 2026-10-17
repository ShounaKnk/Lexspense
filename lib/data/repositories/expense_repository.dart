import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import '../models/expense_view.dart';
import '../models/receipt_image.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/constants.dart';

/// Repository for expenses CRUD with receipt management.
class ExpenseRepository {
  final DatabaseHelper _helper;

  ExpenseRepository(this._helper);

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// All unpaid expenses (reimbursement_id IS NULL) with JOINed details.
  /// This is the dashboard query.
  Future<List<ExpenseView>> getUnpaidExpenses() async {
    final db = await _helper.database;
    final rows = await db.rawQuery('''
      SELECT e.*, 
             m.case_title, 
             c.name AS category_name, 
             c.icon AS category_icon
      FROM expenses e
      JOIN client_matters m ON e.matter_id = m.id
      JOIN expense_categories c ON e.category_id = c.id
      WHERE e.reimbursement_id IS NULL
      ORDER BY e.expense_date DESC, e.created_at DESC
    ''');
    return rows.map(ExpenseView.fromMap).toList();
  }

  /// Expenses belonging to a specific reimbursement batch.
  Future<List<ExpenseView>> getExpensesByReimbursement(int reimbursementId) async {
    final db = await _helper.database;
    final rows = await db.rawQuery('''
      SELECT e.*, 
             m.case_title, 
             c.name AS category_name, 
             c.icon AS category_icon
      FROM expenses e
      JOIN client_matters m ON e.matter_id = m.id
      JOIN expense_categories c ON e.category_id = c.id
      WHERE e.reimbursement_id = ?
      ORDER BY e.expense_date ASC
    ''', [reimbursementId]);
    return rows.map(ExpenseView.fromMap).toList();
  }

  /// Summary for the home widget: (total unpaid paise, count).
  Future<(int, int)> getUnpaidSummary() async {
    final db = await _helper.database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_paise), 0) AS total, COUNT(*) AS cnt
      FROM expenses
      WHERE reimbursement_id IS NULL
    ''');
    final row = rows.first;
    return (row['total'] as int, row['cnt'] as int);
  }

  /// Get receipts for an expense.
  Future<List<ReceiptImage>> getReceiptsForExpense(int expenseId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'receipt_images',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
    return rows.map(ReceiptImage.fromMap).toList();
  }

  /// Get all receipts for a list of expense IDs.
  Future<Map<int, List<ReceiptImage>>> getReceiptsForExpenses(List<int> expenseIds) async {
    if (expenseIds.isEmpty) return {};
    final db = await _helper.database;
    final marks = List.filled(expenseIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM receipt_images WHERE expense_id IN ($marks)',
      expenseIds,
    );
    final map = <int, List<ReceiptImage>>{};
    for (final row in rows) {
      final receipt = ReceiptImage.fromMap(row);
      map.putIfAbsent(receipt.expenseId, () => []).add(receipt);
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Insert an expense and its receipt rows in one transaction.
  /// Returns the new expense ID.
  Future<int> insertExpense(
    Expense expense, {
    List<String> receiptFileNames = const [],
  }) async {
    final db = await _helper.database;
    return db.transaction((txn) async {
      final expenseId = await txn.insert('expenses', expense.toMap());
      for (final fileName in receiptFileNames) {
        await txn.insert('receipt_images', {
          'expense_id': expenseId,
          'file_name': fileName,
        });
      }
      return expenseId;
    });
  }

  /// Update an expense. Throws if the expense is already reimbursed.
  Future<void> updateExpense(Expense expense) async {
    assert(expense.id != null, 'Cannot update an expense without an ID');
    final db = await _helper.database;

    // Check if paid.
    final existing = await db.query(
      'expenses',
      columns: ['reimbursement_id'],
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    if (existing.isNotEmpty && existing.first['reimbursement_id'] != null) {
      throw StateError(
        'Cannot edit a reimbursed expense. Undo the reimbursement first.',
      );
    }

    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  /// Delete an expense. Throws if reimbursed.
  /// Also deletes associated receipt files from disk.
  Future<void> deleteExpense(int id) async {
    final db = await _helper.database;

    // Check if paid.
    final existing = await db.query(
      'expenses',
      columns: ['reimbursement_id'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (existing.isNotEmpty && existing.first['reimbursement_id'] != null) {
      throw StateError(
        'Cannot delete a reimbursed expense. Undo the reimbursement first.',
      );
    }

    // Collect receipt file names before deleting (CASCADE will remove rows).
    final receiptRows = await db.query(
      'receipt_images',
      columns: ['file_name'],
      where: 'expense_id = ?',
      whereArgs: [id],
    );
    final fileNames = receiptRows.map((r) => r['file_name'] as String).toList();

    // Delete the expense (receipt_images rows cascade).
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);

    // Clean up files.
    await _deleteReceiptFiles(fileNames);
  }

  /// Resolve a receipt file name to its full path.
  Future<String> receiptFullPath(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, Constants.receiptsDirName, fileName);
  }

  Future<void> _deleteReceiptFiles(List<String> fileNames) async {
    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = p.join(dir.path, Constants.receiptsDirName);
    for (final name in fileNames) {
      final file = File(p.join(receiptsDir, name));
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
