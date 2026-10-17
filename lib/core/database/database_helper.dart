import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'schema.dart';

/// Singleton database helper. Initializes the SQLite DB with foreign key
/// enforcement and all DDL from [Schema].
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'lexledger.db');
    return openDatabase(
      dbPath,
      version: 2,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Must be set per-connection. This is the only place PRAGMA foreign_keys
  /// goes — it is silently ignored inside transactions (including onCreate).
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create all tables, indexes, and seed default categories.
  /// onCreate is already wrapped in a transaction by sqflite.
  Future<void> _onCreate(Database db, int version) async {
    for (final sql in Schema.createTables) {
      await db.execute(sql);
    }
    for (final sql in Schema.createIndexes) {
      await db.execute(sql);
    }
    // Seed default categories.
    for (final cat in Schema.defaultCategories) {
      await db.insert('expense_categories', cat);
    }
  }

  /// Stepwise migrations. Rule: never edit v1 DDL after release.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      for (final sql in Schema.migrateV1toV2) {
        await db.execute(sql);
      }
    }
  }

  /// Close the database (useful for tests).
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
