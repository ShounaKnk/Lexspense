import 'package:sqflite/sqflite.dart';
import '../models/reimbursement.dart';
import '../../core/database/database_helper.dart';

/// Repository for reimbursement batch operations.
///
/// The critical method is [createReimbursement], which atomically:
/// 1. Sums the selected (still unpaid) expenses
/// 2. Inserts the reimbursement with that total
/// 3. Links the expenses to the reimbursement
/// 4. Verifies the updated row count matches the input
class ReimbursementRepository {
  final DatabaseHelper _helper;

  ReimbursementRepository(this._helper);

  /// Create a reimbursement batch from selected expense IDs.
  ///
  /// The total is computed inside the transaction (not passed in) so
  /// it can never disagree with the linked items.
  /// Throws [ArgumentError] if expenseIds is empty.
  /// Throws [StateError] if any selected expense was already reimbursed.
  Future<int> createReimbursement({
    required List<int> expenseIds,
    required String datePaid,
    String? notes,
  }) async {
    if (expenseIds.isEmpty) {
      throw ArgumentError('No expenses selected');
    }
    final db = await _helper.database;
    return db.transaction((txn) async {
      final marks = List.filled(expenseIds.length, '?').join(',');

      // 1. Sum only the unpaid ones among the selected IDs.
      final totalResult = await txn.rawQuery(
        'SELECT COALESCE(SUM(amount_paise), 0) AS total '
        'FROM expenses '
        'WHERE reimbursement_id IS NULL AND id IN ($marks)',
        expenseIds,
      );
      final total = Sqflite.firstIntValue(totalResult) ?? 0;
      if (total == 0) {
        throw StateError('All selected expenses are already reimbursed');
      }

      // Validate that datePaid is not before the expense_date of any selected expenses
      final dateCheckResult = await txn.rawQuery(
        'SELECT MAX(expense_date) AS max_expense_date '
        'FROM expenses '
        'WHERE id IN ($marks)',
        expenseIds,
      );
      final maxExpenseDate = dateCheckResult.isNotEmpty
          ? dateCheckResult.first['max_expense_date'] as String?
          : null;
      if (maxExpenseDate != null && datePaid.compareTo(maxExpenseDate) < 0) {
        throw ArgumentError(
          'Claim date ($datePaid) cannot be earlier than expense date ($maxExpenseDate)',
        );
      }

      // 2. Insert the reimbursement record.
      final id = await txn.insert('reimbursements', {
        'total_amount_paise': total,
        'date_paid': datePaid,
        'notes': notes,
      });

      // 3. Link the expenses.
      final updated = await txn.rawUpdate(
        'UPDATE expenses SET reimbursement_id = ? '
        'WHERE reimbursement_id IS NULL AND id IN ($marks)',
        [id, ...expenseIds],
      );

      // 4. Verify. If count doesn't match, some were already reimbursed
      //    between the UI loading and this transaction. Roll back.
      if (updated != expenseIds.length) {
        throw StateError(
          'Expected to update ${expenseIds.length} expenses, '
          'but only $updated were unpaid. '
          'Some may have been reimbursed in the meantime.',
        );
      }

      return id;
    });
  }

  /// Undo a reimbursement: deletes the reimbursement row.
  /// FK ON DELETE SET NULL returns all linked expenses to unpaid.
  Future<void> undoReimbursement(int id) async {
    final db = await _helper.database;
    final deleted = await db.delete(
      'reimbursements',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deleted == 0) {
      throw StateError('Reimbursement #$id not found');
    }
  }

  /// All reimbursements with item count, newest first.
  Future<List<Reimbursement>> getAllReimbursements() async {
    final db = await _helper.database;
    final rows = await db.rawQuery('''
      SELECT r.*,
             COUNT(e.id) AS item_count,
             MIN(e.id) AS single_expense_id,
             MIN(c.name) AS single_category_name,
             MIN(c.icon) AS single_category_icon,
             MIN(m.case_title) AS single_matter_title,
             MIN(e.expense_date) AS single_expense_date
      FROM reimbursements r
      LEFT JOIN expenses e ON e.reimbursement_id = r.id
      LEFT JOIN expense_categories c ON e.category_id = c.id
      LEFT JOIN client_matters m ON e.matter_id = m.id
      GROUP BY r.id
      ORDER BY r.date_paid DESC, r.created_at DESC
    ''');
    return rows.map(Reimbursement.fromMap).toList();
  }

  /// Single reimbursement by ID.
  Future<Reimbursement?> getReimbursementById(int id) async {
    final db = await _helper.database;
    final rows = await db.rawQuery('''
      SELECT r.*,
             COUNT(e.id) AS item_count,
             MIN(e.id) AS single_expense_id,
             MIN(c.name) AS single_category_name,
             MIN(c.icon) AS single_category_icon,
             MIN(m.case_title) AS single_matter_title,
             MIN(e.expense_date) AS single_expense_date
      FROM reimbursements r
      LEFT JOIN expenses e ON e.reimbursement_id = r.id
      LEFT JOIN expense_categories c ON e.category_id = c.id
      LEFT JOIN client_matters m ON e.matter_id = m.id
      WHERE r.id = ?
      GROUP BY r.id
    ''', [id]);
    if (rows.isEmpty) return null;
    return Reimbursement.fromMap(rows.first);
  }
}
