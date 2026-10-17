import '../models/receipt_image.dart';
import '../../core/database/database_helper.dart';

/// Repository for receipt_images CRUD operations.
class ReceiptRepository {
  final DatabaseHelper _helper;

  ReceiptRepository(this._helper);

  /// Get all receipts for an expense.
  Future<List<ReceiptImage>> getByExpenseId(int expenseId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'receipt_images',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
      orderBy: 'created_at ASC',
    );
    return rows.map(ReceiptImage.fromMap).toList();
  }

  /// Insert a new receipt image record.
  Future<int> insert(ReceiptImage receipt) async {
    final db = await _helper.database;
    return db.insert('receipt_images', receipt.toMap());
  }

  /// Delete a receipt image record.
  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.delete('receipt_images', where: 'id = ?', whereArgs: [id]);
  }
}
