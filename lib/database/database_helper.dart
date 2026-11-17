import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';
import 'schema.dart';

/// Singleton that owns the SQLite connection. The SQL of the 8-table schema
/// lives in `schema.dart`; every query lives in a DAO. This class only opens,
/// configures, resets and closes the database and runs transactions.
/// DAOs obtain the connection through `DatabaseHelper.instance.database`.
class DatabaseHelper {
  DatabaseHelper._internal() : _inMemory = false;
  static final DatabaseHelper instance = DatabaseHelper._internal();

  /// Test-only: a fresh in-memory database with the full schema.
  /// Each call returns an independent helper, so tests never share state.
  DatabaseHelper.forTesting() : _inMemory = true;

  final bool _inMemory;

  static const String _dbName = 'attendance_system.db';
  static const int _dbVersion = 1;

  // Caching the Future (not the Database) prevents two concurrent first
  // callers from opening the file twice.
  Future<Database>? _dbFuture;

  Future<Database> get database => _dbFuture ??= _open();

  Future<Database> _open() async {
    // inMemoryDatabasePath (':memory:') needs no file and no path lookup.
    final String path = _inMemory
        ? inMemoryDatabasePath
        : join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: Migrations.upgrade,
      // sqflite caches connections by path; without this, every ':memory:'
      // open would share one cached instance across tests.
      singleInstance: !_inMemory,
    );
  }

  // Runs on EVERY open, outside any transaction, so the pragma takes effect.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Runs once, when the file is first created (or version goes 0 -> 1).
  Future<void> _onCreate(Database db, int version) async {
    for (final String statement in createStatements) {
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

  /// Runs [action] inside one SQLite transaction. If [action] throws,
  /// every write it made is rolled back. Returns whatever [action] returns.
  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final Database db = await database;
    return db.transaction(action);
  }
}
