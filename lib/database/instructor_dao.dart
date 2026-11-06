import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

/// Minimal for now (login needs it). Extend in step 11 (instructor CRUD).
class InstructorDao {
  InstructorDao(this._helper);
  final DatabaseHelper _helper;

  Future<int?> findIdByUserId(int userId, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _helper.database;
    final rows = await db.rawQuery(
      'SELECT id FROM instructors WHERE user_id = ? LIMIT 1',
      [userId],
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }
}
