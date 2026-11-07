import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi.dart';

/// Web: SQLite runs as WebAssembly in a worker.
void initDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
