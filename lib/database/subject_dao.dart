import 'package:sqflite/sqflite.dart';

import '../models/subject.dart';
import '../utils/arabic_text.dart';
import 'database_helper.dart';

class SubjectDao {
  SubjectDao(this._helper);
  final DatabaseHelper _helper;

  Future<DatabaseExecutor> _db(DatabaseExecutor? executor) async =>
      executor ?? await _helper.database;

  Future<List<Subject>> findAll({bool includeInactive = true, DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    final where = includeInactive ? null : 'is_active = 1';
    final rows = await db.query(
      'subjects',
      where: where,
      orderBy: 'subject_name COLLATE NOCASE, id DESC',
    );
    return rows.map(Subject.fromMap).toList();
  }

  Future<List<Subject>> search(
    String query, {
    bool includeInactive = true,
    DatabaseExecutor? executor,
  }) async {
    final needle = normalizeArabic(query.trim());
    final all = await findAll(includeInactive: includeInactive, executor: executor);
    if (needle.isEmpty) return all;
    return all.where((subject) {
      final haystack = normalizeArabic(
        '${subject.subjectCode} ${subject.subjectName}',
      );
      return haystack.contains(needle);
    }).toList();
  }

  Future<Subject?> findById(int id, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    final rows = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Subject.fromMap(rows.first);
  }

  Future<Subject?> findByCode(String code, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    final rows = await db.query(
      'subjects',
      where: 'subject_code = ? COLLATE NOCASE',
      whereArgs: [code],
      limit: 1,
    );
    return rows.isEmpty ? null : Subject.fromMap(rows.first);
  }

  Future<int> insert(Subject subject, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    return db.insert('subjects', subject.toMap());
  }

  Future<void> update(Subject subject, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    if (subject.id == null) {
      throw ArgumentError('Subject id is required for update');
    }
    await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<void> setActive(int id, bool active, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    await db.update(
      'subjects',
      {'is_active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteById(int id, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasSectionUsage(int subjectId, {DatabaseExecutor? executor}) async {
    final db = await _db(executor);
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM sections WHERE subject_id = ?',
        [subjectId],
      ),
    ) ?? 0;
    return count > 0;
  }
}
