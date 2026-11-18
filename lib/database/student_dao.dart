import 'package:sqflite/sqflite.dart';

import '../models/student.dart';
import '../utils/arabic_text.dart';
import 'database_helper.dart';

class StudentDao {
  StudentDao(this._helper);
  final DatabaseHelper _helper;

  Future<DatabaseExecutor> _db(DatabaseExecutor? executor) async =>
      executor ?? await _helper.database;

  Future<List<Student>> findAll({
    bool includeInactive = true,
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    final where = includeInactive ? null : 'is_active = 1';
    final rows = await db.query(
      'students',
      where: where,
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(Student.fromMap).toList();
  }

  Future<List<Student>> search(
    String query, {
    bool includeInactive = true,
    DatabaseExecutor? executor,
  }) async {
    final needle = normalizeArabic(query.trim());
    final all = await findAll(
      includeInactive: includeInactive,
      executor: executor,
    );
    if (needle.isEmpty) return all;
    return all.where((student) {
      final haystack = normalizeArabic(
        '${student.fullName} ${student.studentNumber}',
      );
      return haystack.contains(needle);
    }).toList();
  }

  Future<Student?> findById(int id, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    final rows = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Student.fromMap(rows.first);
  }

  Future<Student?> findByNumber(
    String number, {
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    final rows = await db.query(
      'students',
      where: 'student_number = ? COLLATE NOCASE',
      whereArgs: [number],
      limit: 1,
    );
    return rows.isEmpty ? null : Student.fromMap(rows.first);
  }

  Future<Student?> findByEmail(
    String email, {
    int? excludeStudentId,
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    final rows = await db.query(
      'students',
      where: 'email = ? COLLATE NOCASE AND id <> ?',
      whereArgs: [email, excludeStudentId ?? -1],
      limit: 1,
    );
    return rows.isEmpty ? null : Student.fromMap(rows.first);
  }

  Future<int> insert(Student student, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    return db.insert('students', student.toMap());
  }

  Future<void> update(Student student, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    if (student.id == null) {
      throw ArgumentError('Student id is required for update');
    }
    await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<void> setActive(
    int id,
    bool active, {
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    await db.update(
      'students',
      {'is_active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteById(int id, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasRelatedRows(
    int studentId, {
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    final enrollments =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM enrollments WHERE student_id = ?',
            [studentId],
          ),
        ) ??
        0;
    final attendance =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM attendance WHERE student_id = ?',
            [studentId],
          ),
        ) ??
        0;
    return enrollments > 0 || attendance > 0;
  }

  Future<List<StudentEnrollment>> findEnrollments(
    int studentId, {
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    final rows = await db.rawQuery(
      '''
      SELECT sub.subject_code, sub.subject_name, sec.section_number,
             sec.semester, sec.academic_year, e.status
      FROM enrollments e
      JOIN sections sec ON sec.id = e.section_id
      JOIN subjects sub ON sub.id = sec.subject_id
      WHERE e.student_id = ?
      ORDER BY sec.academic_year DESC, sec.semester, sub.subject_name
      ''',
      [studentId],
    );
    return rows.map(StudentEnrollment.fromMap).toList();
  }

  Future<List<StudentAttendance>> findAttendance(
    int studentId, {
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    final rows = await db.rawQuery(
      '''
      SELECT sub.subject_name, sec.section_number, l.lecture_date,
             l.start_time, l.end_time, l.topic, a.attendance_status
      FROM attendance a
      JOIN lectures l ON l.id = a.lecture_id
      JOIN sections sec ON sec.id = l.section_id
      JOIN subjects sub ON sub.id = sec.subject_id
      WHERE a.student_id = ?
      ORDER BY l.lecture_date DESC, l.start_time DESC, a.id DESC
      ''',
      [studentId],
    );
    return rows.map(StudentAttendance.fromMap).toList();
  }
}
