/// Raw SQL DDL constants for the Lexspense database.
/// 
/// These are executed in [DatabaseHelper._onCreate]. They must NOT contain
/// `PRAGMA` statements because onCreate runs inside a transaction where
/// PRAGMA is silently ignored.
class Schema {
  Schema._();

  static const List<String> createTables = [
    '''
    CREATE TABLE court_forums (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE COLLATE NOCASE,
      status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Archived')),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    ''',
    '''
    CREATE TABLE client_matters (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      case_title TEXT NOT NULL UNIQUE COLLATE NOCASE,
      forum_id INTEGER,
      status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Archived')),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (forum_id) REFERENCES court_forums(id) ON DELETE SET NULL
    )
    ''',
    '''
    CREATE TABLE expense_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE COLLATE NOCASE,
      icon TEXT,
      is_active INTEGER NOT NULL DEFAULT 1
    )
    ''',
    '''
    CREATE TABLE reimbursements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      total_amount_paise INTEGER NOT NULL CHECK (total_amount_paise > 0),
      date_paid TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    ''',
    '''
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      matter_id INTEGER NOT NULL,
      category_id INTEGER NOT NULL,
      reimbursement_id INTEGER,
      amount_paise INTEGER NOT NULL CHECK (amount_paise > 0),
      expense_date TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (matter_id) REFERENCES client_matters(id) ON DELETE RESTRICT,
      FOREIGN KEY (category_id) REFERENCES expense_categories(id) ON DELETE RESTRICT,
      FOREIGN KEY (reimbursement_id) REFERENCES reimbursements(id) ON DELETE SET NULL
    )
    ''',
    '''
    CREATE TABLE receipt_images (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      expense_id INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
    )
    ''',
  ];

  static const List<String> createIndexes = [
    'CREATE INDEX idx_expenses_reimbursement ON expenses(reimbursement_id)',
    'CREATE INDEX idx_expenses_matter ON expenses(matter_id)',
    'CREATE INDEX idx_expenses_category ON expenses(category_id)',
    'CREATE INDEX idx_expenses_date ON expenses(expense_date)',
    'CREATE INDEX idx_receipts_expense ON receipt_images(expense_id)',
    'CREATE INDEX idx_court_forums_status ON court_forums(status)',
    'CREATE INDEX idx_matters_forum ON client_matters(forum_id)',
  ];

  /// Default expense categories seeded on first run.
  static const List<Map<String, Object>> defaultCategories = [
    {'name': 'Court Fees', 'icon': 'gavel', 'is_active': 1},
    {'name': 'Printing & Stationery', 'icon': 'print', 'is_active': 1},
    {'name': 'Travel & Transport', 'icon': 'directions_car', 'is_active': 1},
    {'name': 'Fuel', 'icon': 'local_gas_station', 'is_active': 1},
    {'name': 'Filing & Stamps', 'icon': 'local_post_office', 'is_active': 1},
    {'name': 'Miscellaneous', 'icon': 'more_horiz', 'is_active': 1},
  ];

  /// Migration statements for v1 -> v2.
  /// Adds the court_forums table and migrates the old text-based forum column
  /// to a proper foreign key relationship.
  static const List<String> migrateV1toV2 = [
    '''
    CREATE TABLE court_forums (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE COLLATE NOCASE,
      status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Archived')),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    ''',
    'CREATE INDEX idx_court_forums_status ON court_forums(status)',
    // Insert unique forum names from existing client_matters
    '''
    INSERT OR IGNORE INTO court_forums (name)
    SELECT DISTINCT forum FROM client_matters WHERE forum IS NOT NULL AND forum != ''
    ''',
    // Add forum_id column
    'ALTER TABLE client_matters ADD COLUMN forum_id INTEGER REFERENCES court_forums(id) ON DELETE SET NULL',
    // Populate forum_id from matching court_forums
    '''
    UPDATE client_matters SET forum_id = (
      SELECT cf.id FROM court_forums cf WHERE cf.name = client_matters.forum
    ) WHERE forum IS NOT NULL AND forum != ''
    ''',
    'CREATE INDEX idx_matters_forum ON client_matters(forum_id)',
  ];
}

