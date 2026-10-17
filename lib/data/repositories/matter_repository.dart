import '../models/client_matter.dart';
import '../../core/database/database_helper.dart';

/// Repository for client_matters CRUD operations.
class MatterRepository {
  final DatabaseHelper _helper;

  MatterRepository(this._helper);

  /// All active matters (for the picker), with forum name joined.
  Future<List<ClientMatter>> getActive() async {
    final db = await _helper.database;
    final rows = await db.rawQuery('''
      SELECT cm.*, cf.name AS forum_name
      FROM client_matters cm
      LEFT JOIN court_forums cf ON cm.forum_id = cf.id
      WHERE cm.status = 'Active'
      ORDER BY cm.case_title COLLATE NOCASE ASC
    ''');
    return rows.map(ClientMatter.fromMap).toList();
  }

  /// All matters (for the management screen), with forum name joined.
  Future<List<ClientMatter>> getAll() async {
    final db = await _helper.database;
    final rows = await db.rawQuery('''
      SELECT cm.*, cf.name AS forum_name
      FROM client_matters cm
      LEFT JOIN court_forums cf ON cm.forum_id = cf.id
      ORDER BY CASE cm.status WHEN 'Active' THEN 0 ELSE 1 END,
               cm.case_title COLLATE NOCASE ASC
    ''');
    return rows.map(ClientMatter.fromMap).toList();
  }

  /// Get a single matter by ID.
  Future<ClientMatter?> getById(int id) async {
    final db = await _helper.database;
    final rows = await db.rawQuery('''
      SELECT cm.*, cf.name AS forum_name
      FROM client_matters cm
      LEFT JOIN court_forums cf ON cm.forum_id = cf.id
      WHERE cm.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;
    return ClientMatter.fromMap(rows.first);
  }

  /// Insert a new matter. Returns the new ID.
  Future<int> insert(ClientMatter matter) async {
    final db = await _helper.database;
    return db.insert('client_matters', matter.toMap());
  }

  /// Update matter title and/or forum.
  Future<void> update(ClientMatter matter) async {
    assert(matter.id != null, 'Cannot update a matter without an ID');
    final db = await _helper.database;
    await db.update(
      'client_matters',
      matter.toMap(),
      where: 'id = ?',
      whereArgs: [matter.id],
    );
  }

  /// Archive a matter (sets status to 'Archived').
  Future<void> archive(int id) async {
    final db = await _helper.database;
    await db.update(
      'client_matters',
      {'status': 'Archived'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Unarchive a matter (sets status back to 'Active').
  Future<void> unarchive(int id) async {
    final db = await _helper.database;
    await db.update(
      'client_matters',
      {'status': 'Active'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a matter. Throws DatabaseException if linked to expenses (FK RESTRICT).
  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.delete('client_matters', where: 'id = ?', whereArgs: [id]);
  }
}
