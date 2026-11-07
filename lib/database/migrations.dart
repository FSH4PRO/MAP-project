import 'package:sqflite/sqflite.dart';

/// Empty stub: the schema is at version 1, so nothing runs yet.
///
/// When someone needs a schema change: bump `_dbVersion` in
/// `DatabaseHelper`, add a step below guarded by `oldVersion < N`, and also
/// update `schema.dart` so fresh installs get the same final shape.
class Migrations {
  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Example for the future:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE students ADD COLUMN national_id TEXT');
    // }
  }
}
