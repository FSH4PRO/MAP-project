import 'package:sqflite/sqflite.dart';

import '../models/instructor.dart';
import 'database_helper.dart';

/// SQL only. No permission checks here (services do that).
/// Pass [executor] (a Transaction) to take part in a larger transaction.
class InstructorDao {
  InstructorDao(this._helper);
  final DatabaseHelper _helper;

  // Instructor joined with its user account (never selects password_hash).
  static const String _infoSelect = '''
    SELECT i.id, i.user_id, i.employee_number, i.specialization,
           u.full_name, u.username, u.email, u.is_active
    FROM instructors i
    JOIN users u ON u.id = i.user_id
  ''';

  Future<DatabaseExecutor> _db(DatabaseExecutor? e) async =>
      e ?? await _helper.database;

  Future<int?> findIdByUserId(int userId, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    final rows = await db.rawQuery(
      'SELECT id FROM instructors WHERE user_id = ? LIMIT 1',
      [userId],
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  Future<List<InstructorInfo>> findAllInfo({DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    final rows = await db.rawQuery(
      '$_infoSelect ORDER BY u.full_name COLLATE NOCASE, i.id',
    );
    return rows.map(InstructorInfo.fromMap).toList();
  }

  Future<InstructorInfo?> findInfoById(
    int id, {
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    final rows = await db.rawQuery('$_infoSelect WHERE i.id = ? LIMIT 1', [id]);
    return rows.isEmpty ? null : InstructorInfo.fromMap(rows.first);
  }

  Future<int> insert(
    Instructor instructor, {
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    return db.insert('instructors', instructor.toMap());
  }

  Future<void> updateDetails(
    int id, {
    String? employeeNumber,
    String? specialization,
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    await db.rawUpdate(
      'UPDATE instructors SET employee_number = ?, specialization = ? '
      'WHERE id = ?',
      [employeeNumber, specialization, id],
    );
  }
}
