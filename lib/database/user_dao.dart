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

  Future<List<User>> findAll({DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    final rows = await db.rawQuery(
      'SELECT * FROM users ORDER BY full_name COLLATE NOCASE, id',
    );
    return rows.map(User.fromMap).toList();
  }

  /// Case-insensitive lookup (the schema's UNIQUE is case-sensitive).
  Future<User?> findByUsername(
    String username, {
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    final rows = await db.rawQuery(
      'SELECT * FROM users WHERE username = ? COLLATE NOCASE LIMIT 1',
      [username],
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  /// Case-insensitive. The schema has no UNIQUE on email, so the service uses
  /// this to enforce "no duplicate email". [excludeUserId] skips one user
  /// (the one being edited).
  Future<User?> findByEmail(
    String email, {
    int? excludeUserId,
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    final rows = await db.rawQuery(
      'SELECT * FROM users WHERE email = ? COLLATE NOCASE AND id <> ? LIMIT 1',
      [email, excludeUserId ?? -1],
    );
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<User?> findById(int id, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    final rows = await db.rawQuery('SELECT * FROM users WHERE id = ? LIMIT 1', [
      id,
    ]);
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<int> insert(User user, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    return db.insert('users', user.toMap());
  }

  Future<void> updatePasswordHash(
    int id,
    String hash, {
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    await db.rawUpdate('UPDATE users SET password_hash = ? WHERE id = ?', [
      hash,
      id,
    ]);
  }

  Future<void> setActive(
    int id,
    bool active, {
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    await db.rawUpdate('UPDATE users SET is_active = ? WHERE id = ?', [
      active ? 1 : 0,
      id,
    ]);
  }

  /// Name and email only; username, role and password have their own paths.
  Future<void> updateProfile(
    int id, {
    required String fullName,
    String? email,
    DatabaseExecutor? executor,
  }) async {
    final db = await _db(executor);
    await db.rawUpdate(
      'UPDATE users SET full_name = ?, email = ? WHERE id = ?',
      [fullName, email, id],
    );
  }
}
