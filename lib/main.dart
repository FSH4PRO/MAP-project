import 'package:flutter/material.dart';

import 'database/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final DatabaseHelper helper = DatabaseHelper.instance;
  await helper.seedSampleData(); // task 3

  final db = await helper.database;
  final int lectureId =
      (await db.query('lectures', limit: 1)).first['id'] as int;
  final int studentId =
      (await db.query('students', where: "student_number = '2026001'"))
          .first['id'] as int;

  // Task 4: guard against re-running the app (UNIQUE would throw).
  final already = await db.query('attendance',
      where: 'lecture_id = ? AND student_id = ?',
      whereArgs: [lectureId, studentId]);
  if (already.isEmpty) {
    await helper.recordAttendance(
      lectureId: lectureId,
      studentId: studentId,
      status: 'present',
    );
  }

  // Verification: join across 3 tables to prove the relationships work.
  final rows = await db.rawQuery('''
    SELECT s.student_number, s.full_name, l.lecture_date, a.attendance_status
    FROM attendance a
    JOIN students s ON s.id = a.student_id
    JOIN lectures l ON l.id = a.lecture_id
  ''');
  debugPrint('ATTENDANCE: $rows');

  runApp(const MaterialApp(
    home: Scaffold(body: Center(child: Text('Database ready'))),
  ));
}