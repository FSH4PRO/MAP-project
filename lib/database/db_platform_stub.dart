import 'dart:io' show Platform;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Android/iOS: sqflite installs its own factory, nothing to do.
/// Windows/Linux/macOS: use the FFI factory (SQLite through dart:ffi).
void initDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}