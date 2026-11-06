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
  // =====================================================================
  // Simple data-access methods used by the UI
  // =====================================================================

  // ---- Students ----
  Future<int> insertStudent(String number, String name) async {
    final Database db = await database;
    return db.insert('students', {'student_number': number, 'full_name': name});
  }

  Future<List<Map<String, Object?>>> getStudents() async {
    final Database db = await database;
    return db.query('students', orderBy: 'id DESC');
  }

  // ---- Subjects ----
  Future<int> insertSubject(String code, String name) async {
    final Database db = await database;
    return db.insert('subjects', {'subject_code': code, 'subject_name': name});
  }

  Future<List<Map<String, Object?>>> getSubjects() async {
    final Database db = await database;
    return db.query('subjects', orderBy: 'id DESC');
  }

  // ---- Sections ----
  // sections.instructor_id is NOT NULL. For this simple version we reuse the
  // first instructor and create one default instructor if none exists.
  Future<int> _ensureInstructorId(DatabaseExecutor db) async {
    final rows = await db.query('instructors', columns: ['id'], limit: 1);
    if (rows.isNotEmpty) return rows.first['id'] as int;

    final int userId = await db.insert('users', {
      'username': 'default_instructor',
      'password_hash': 'placeholder_hash', // real hashing comes later
      'full_name': 'Default Instructor',
      'user_type': 'instructor',
    });
    return db.insert('instructors', {'user_id': userId});
  }

  Future<int> insertSection(
      int subjectId, String number, String semester, String year) async {
    final Database db = await database;
    return db.transaction((txn) async {
      final int instructorId = await _ensureInstructorId(txn);
      return txn.insert('sections', {
        'subject_id': subjectId,
        'instructor_id': instructorId,
        'section_number': number,
        'semester': semester,
        'academic_year': year,
      });
    });
  }

  Future<List<Map<String, Object?>>> getSections() async {
    final Database db = await database;
    return db.rawQuery('''
      SELECT sec.id, sub.subject_code, sub.subject_name,
            sec.section_number, sec.semester, sec.academic_year,
            (SELECT COUNT(*) FROM enrollments e
              WHERE e.section_id = sec.id AND e.status = 'active') AS enrolled
      FROM sections sec
      JOIN subjects sub ON sub.id = sec.subject_id
      ORDER BY sec.id DESC
    ''');
  }

  // ---- Enrollments ----
  Future<int> enrollStudent(int studentId, int sectionId) async {
    final Database db = await database;
    return db.insert(
        'enrollments', {'student_id': studentId, 'section_id': sectionId});
  }

  // ---- Lectures ----
  Future<int> insertLecture(int sectionId, String date, String start,
      String end, String topic) async {
    final Database db = await database;
    return db.insert('lectures', {
      'section_id': sectionId,
      'lecture_date': date,
      'start_time': start,
      'end_time': end,
      'topic': topic.isEmpty ? null : topic,
    });
  }

  Future<List<Map<String, Object?>>> getLectures() async {
    final Database db = await database;
    return db.rawQuery('''
      SELECT l.id, l.section_id, l.lecture_date, l.start_time, l.end_time, l.topic,
        l.status, sub.subject_code, sec.section_number
      FROM lectures l
      JOIN sections sec ON sec.id = l.section_id
      JOIN subjects sub ON sub.id = sec.subject_id
      ORDER BY l.lecture_date DESC, l.start_time DESC
    ''');
  }

  // ---- Attendance ----
  /// Active students of the lecture's section, with their saved status
  /// (attendance_status is null if nothing was recorded yet).
  Future<List<Map<String, Object?>>> getLectureStudents(int lectureId) async {
    final Database db = await database;
    return db.rawQuery('''
      SELECT s.id, s.student_number, s.full_name, a.attendance_status
      FROM lectures l
      JOIN enrollments e ON e.section_id = l.section_id AND e.status = 'active'
      JOIN students s ON s.id = e.student_id
      LEFT JOIN attendance a ON a.lecture_id = l.id AND a.student_id = s.id
      WHERE l.id = ?
      ORDER BY s.full_name
    ''', [lectureId]);
  }

  /// Saves {studentId: status} for one lecture in a single transaction.
  /// Update first; insert only if no row existed. This keeps the UNIQUE
  /// (lecture_id, student_id) rule and avoids ConflictAlgorithm.replace.
  Future<void> saveAttendance(int lectureId, Map<int, String> statuses) async {
    final Database db = await database;
    await db.transaction((txn) async {
      final lecture = await txn.query('lectures',
          columns: ['status'], where: 'id = ?', whereArgs: [lectureId]);
      if (lecture.isEmpty || lecture.first['status'] == 'cancelled') {
        throw StateError('Lecture does not exist or was cancelled.');
      }
      for (final entry in statuses.entries) {
        final int updated = await txn.update(
          'attendance',
          {'attendance_status': entry.value},
          where: 'lecture_id = ? AND student_id = ?',
          whereArgs: [lectureId, entry.key],
        );
        if (updated == 0) {
          await txn.insert('attendance', {
            'lecture_id': lectureId,
            'student_id': entry.key,
            'attendance_status': entry.value,
          });
        }
      }
    });
  }


    /// Read-only view: one row per saved attendance record.
  Future<List<Map<String, Object?>>> getAttendanceRecords() async {
    final Database db = await database;
    return db.rawQuery('''
      SELECT s.student_number, s.full_name, sub.subject_code,
        l.lecture_date, l.start_time, a.attendance_status
      FROM attendance a
      JOIN students s ON s.id = a.student_id
      JOIN lectures l ON l.id = a.lecture_id
      JOIN sections sec ON sec.id = l.section_id
      JOIN subjects sub ON sub.id = sec.subject_id
      ORDER BY s.full_name, l.lecture_date, l.start_time
    ''');
  }
}