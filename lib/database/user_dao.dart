import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import 'database_helper.dart';

/// SQL only. No permission checks here (services do that).
/// Pass [executor] (a Transaction) to take part in a larger transaction.
class UserDao {
  UserDao(this._helper);
  final DatabaseHelper _helper;

  Future<DatabaseExecutor> _db(DatabaseExecutor? e) async =>
      e ?? await _helper.database;

  Future<int> count({DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM users');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Case-insensitive lookup (the schema's UNIQUE is case-sensitive).
  Future<User?> findByUsername(String username,
      {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    final rows = await db.rawQuery(
      'SELECT * FROM users WHERE username = ? COLLATE NOCASE LIMIT 1',
      [username],
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<User?> findById(int id, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    final rows =
        await db.rawQuery('SELECT * FROM users WHERE id = ? LIMIT 1', [id]);
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<int> insert(User user, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    return db.insert('users', user.toMap());
  }

  Future<void> updatePasswordHash(int id, String hash,
      {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    await db.rawUpdate(
      'UPDATE users SET password_hash = ? WHERE id = ?',
      [hash, id],
    );
  }
}
