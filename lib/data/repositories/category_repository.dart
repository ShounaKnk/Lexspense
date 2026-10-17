import '../models/expense_category.dart';
import '../../core/database/database_helper.dart';

/// Repository for expense_categories CRUD operations.
class CategoryRepository {
  final DatabaseHelper _helper;

  CategoryRepository(this._helper);

  /// All active categories (for the picker).
  Future<List<ExpenseCategory>> getActive() async {
    final db = await _helper.database;
    final rows = await db.query(
      'expense_categories',
      where: 'is_active = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(ExpenseCategory.fromMap).toList();
  }

  /// All categories including deactivated (for management screen).
  Future<List<ExpenseCategory>> getAll() async {
    final db = await _helper.database;
    final rows = await db.query(
      'expense_categories',
      orderBy: 'is_active DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(ExpenseCategory.fromMap).toList();
  }

  /// Insert a new category. Returns the new ID.
  Future<int> insert(ExpenseCategory category) async {
    final db = await _helper.database;
    return db.insert('expense_categories', category.toMap());
  }

  /// Update category name and/or icon.
  Future<void> update(ExpenseCategory category) async {
    assert(category.id != null, 'Cannot update a category without an ID');
    final db = await _helper.database;
    await db.update(
      'expense_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Deactivate a category (soft delete). Expenses keep their FK reference.
  Future<void> deactivate(int id) async {
    final db = await _helper.database;
    await db.update(
      'expense_categories',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Reactivate a deactivated category.
  Future<void> activate(int id) async {
    final db = await _helper.database;
    await db.update(
      'expense_categories',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
