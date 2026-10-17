import '../models/court_forum.dart';
import '../../core/database/database_helper.dart';

/// Repository for court_forums CRUD operations.
class CourtForumRepository {
  final DatabaseHelper _helper;

  CourtForumRepository(this._helper);

  /// All active forums (for the dropdown picker).
  Future<List<CourtForum>> getActive() async {
    final db = await _helper.database;
    final rows = await db.query(
      'court_forums',
      where: "status = ?",
      whereArgs: ['Active'],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(CourtForum.fromMap).toList();
  }

  /// All forums (for the management screen).
  Future<List<CourtForum>> getAll() async {
    final db = await _helper.database;
    final rows = await db.query(
      'court_forums',
      orderBy: "CASE status WHEN 'Active' THEN 0 ELSE 1 END, name COLLATE NOCASE ASC",
    );
    return rows.map(CourtForum.fromMap).toList();
  }

  /// Get a single forum by ID.
  Future<CourtForum?> getById(int id) async {
    final db = await _helper.database;
    final rows = await db.query('court_forums', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return CourtForum.fromMap(rows.first);
  }

  /// Insert a new forum. Returns the new ID.
  Future<int> insert(CourtForum forum) async {
    final db = await _helper.database;
    return db.insert('court_forums', forum.toMap());
  }

  /// Update forum name.
  Future<void> update(CourtForum forum) async {
    assert(forum.id != null, 'Cannot update a forum without an ID');
    final db = await _helper.database;
    await db.update(
      'court_forums',
      forum.toMap(),
      where: 'id = ?',
      whereArgs: [forum.id],
    );
  }

  /// Archive a forum (sets status to 'Archived').
  Future<void> archive(int id) async {
    final db = await _helper.database;
    await db.update(
      'court_forums',
      {'status': 'Archived'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Unarchive a forum (sets status back to 'Active').
  Future<void> unarchive(int id) async {
    final db = await _helper.database;
    await db.update(
      'court_forums',
      {'status': 'Active'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a forum. May fail if referenced by client_matters (FK RESTRICT).
  Future<void> delete(int id) async {
    final db = await _helper.database;
    await db.delete('court_forums', where: 'id = ?', whereArgs: [id]);
  }
}
