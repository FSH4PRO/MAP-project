import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton that owns the SQLite connection and creates the 8-table schema.
/// DAOs obtain the connection through `DatabaseHelper.instance.database`.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'attendance_system.db';
  static const int _dbVersion = 1;

  // Caching the Future (not the Database) prevents two concurrent first
  // callers from opening the file twice.
  Future<Database>? _dbFuture;

  Future<Database> get database => _dbFuture ??= _open();

  Future<Database> _open() async {
    final String path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  // Runs on EVERY open, outside any transaction, so the pragma takes effect.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Runs once, when the file is first created (or version goes 0 -> 1).
  Future<void> _onCreate(Database db, int version) async {
    for (final String statement in _createStatements) {
      await db.execute(statement); // one statement per execute() call
    }
  }

  /// Development helper: deletes the file so the next open recreates it.
  Future<void> resetDatabase() async {
    await close();
    await deleteDatabase(join(await getDatabasesPath(), _dbName));
  }

  Future<void> close() async {
    final Future<Database>? pending = _dbFuture;
    _dbFuture = null;
    if (pending != null) await (await pending).close();
  }

  // ---------------------------------------------------------------------
  // Schema (order matters: referenced tables are created first)
  // ---------------------------------------------------------------------
  static const List<String> _createStatements = [
    // 1. users
    '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      full_name TEXT NOT NULL,
      email TEXT,
      user_type TEXT NOT NULL
        CHECK (user_type IN ('admin', 'registrar', 'instructor', 'supervisor')),
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    ''',
    // 2. students
    '''
    CREATE TABLE students (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_number TEXT NOT NULL UNIQUE,
      full_name TEXT NOT NULL,
      email TEXT,
      phone TEXT,
      department TEXT,
      enrollment_year INTEGER,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    ''',
    // 3. instructors (1:1 extension of users)
    '''
    CREATE TABLE instructors (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL UNIQUE,
      employee_number TEXT UNIQUE,
      specialization TEXT,
      FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE RESTRICT
    )
    ''',
    // 4. subjects
    '''
    CREATE TABLE subjects (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subject_code TEXT NOT NULL UNIQUE,
      subject_name TEXT NOT NULL,
      credit_hours INTEGER NOT NULL DEFAULT 1,
      department TEXT,
      is_active INTEGER NOT NULL DEFAULT 1
    )
    ''',
    // 5. sections (a subject taught by one instructor in one semester)
    '''
    CREATE TABLE sections (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subject_id INTEGER NOT NULL,
      instructor_id INTEGER NOT NULL,
      section_number TEXT NOT NULL,
      semester TEXT NOT NULL,
      academic_year TEXT NOT NULL,
      FOREIGN KEY (subject_id) REFERENCES subjects(id)
        ON DELETE RESTRICT,
      FOREIGN KEY (instructor_id) REFERENCES instructors(id)
        ON DELETE RESTRICT,
      UNIQUE (subject_id, section_number, semester, academic_year)
    )
    ''',
    // 6. enrollments (students <-> sections, many-to-many)
    '''
    CREATE TABLE enrollments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_id INTEGER NOT NULL,
      section_id INTEGER NOT NULL,
      enrolled_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'withdrawn')),
      FOREIGN KEY (student_id) REFERENCES students(id)
        ON DELETE RESTRICT,
      FOREIGN KEY (section_id) REFERENCES sections(id)
        ON DELETE RESTRICT,
      UNIQUE (student_id, section_id)
    )
    ''',
    // 7. lectures
    '''
    CREATE TABLE lectures (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      section_id INTEGER NOT NULL,
      lecture_date TEXT NOT NULL,
      start_time TEXT NOT NULL,
      end_time TEXT NOT NULL,
      topic TEXT,
      status TEXT NOT NULL DEFAULT 'scheduled'
        CHECK (status IN ('scheduled', 'completed', 'cancelled')),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (section_id) REFERENCES sections(id)
        ON DELETE RESTRICT
    )
    ''',
    // 8. attendance (UNIQUE pair enforces FR26: no duplicate record)
    '''
    CREATE TABLE attendance (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      lecture_id INTEGER NOT NULL,
      student_id INTEGER NOT NULL,
      attendance_status TEXT NOT NULL
        CHECK (attendance_status IN ('present', 'absent', 'late', 'excused')),
      notes TEXT,
      recorded_by INTEGER,
      recorded_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (lecture_id) REFERENCES lectures(id)
        ON DELETE RESTRICT,
      FOREIGN KEY (student_id) REFERENCES students(id)
        ON DELETE RESTRICT,
      FOREIGN KEY (recorded_by) REFERENCES users(id)
        ON DELETE SET NULL,
      UNIQUE (lecture_id, student_id)
    )
    ''',
    // Indexes for search and reports
    'CREATE INDEX idx_students_number ON students(student_number)',
    'CREATE INDEX idx_subjects_code ON subjects(subject_code)',
    'CREATE INDEX idx_sections_instructor ON sections(instructor_id)',
    'CREATE INDEX idx_enrollments_section ON enrollments(section_id, status)',
    'CREATE INDEX idx_lectures_section_date ON lectures(section_id, lecture_date)',
    'CREATE INDEX idx_attendance_student ON attendance(student_id, attendance_status)',
    'CREATE INDEX idx_attendance_lecture ON attendance(lecture_id)',
  ];
}