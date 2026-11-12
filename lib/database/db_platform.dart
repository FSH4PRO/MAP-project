// Picks the right SQLite backend per platform at compile time.
// Android / iOS: sqflite's default factory (nothing to do).
// Web: sqflite_common_ffi_web (run `dart run sqflite_common_ffi_web:setup` once).
export 'db_platform_stub.dart'
    if (dart.library.js_interop) 'db_platform_web.dart';
