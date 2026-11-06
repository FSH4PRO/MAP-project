import 'package:flutter/material.dart';

import 'database/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: HomePage()));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper db = DatabaseHelper.instance;

  // Text inputs
  final studentNumber = TextEditingController();
  final studentName = TextEditingController();
  final courseCode = TextEditingController();
  final courseName = TextEditingController();
  final lectureDate = TextEditingController(text: '2026-11-02');
  final startTime = TextEditingController(text: '09:00');
  final endTime = TextEditingController(text: '10:30');

  // Data shown on screen
  List<Map<String, Object?>> students = [];
  List<Map<String, Object?>> courses = []; // rows from getSections()
  List<Map<String, Object?>> lectures = [];

  int? lectureCourseId; // section id chosen when adding a lecture
  int? attendanceLectureId; // lecture chosen for attendance
  final Map<int, String> status = {}; // studentId -> status

  static const List<String> statuses = ['present', 'absent', 'late', 'excused'];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = await db.getStudents();
    final c = await db.getSections();
    final l = await db.getLectures();
    setState(() {
      students = s;
      courses = c;
      lectures = l;
      for (final st in students) {
        status.putIfAbsent(st['id'] as int, () => 'present');
      }
    });
  }

  void say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  // Runs a DB action, reloads the lists, and shows the result.
  Future<void> run(Future<void> Function() action, String okText) async {
    try {
      await action();
      await load();
      say(okText);
    } catch (e) {
      say(e.toString().contains('UNIQUE') ? 'Already exists.' : 'Error: $e');
    }
  }

  Future<void> addStudent() async {
    if (studentNumber.text.trim().isEmpty || studentName.text.trim().isEmpty) {
      say('Enter number and name.');
      return;
    }
    await run(
      () => db.insertStudent(studentNumber.text.trim(), studentName.text.trim()),
      'Student added',
    );
    studentNumber.clear();
    studentName.clear();
  }

  Future<void> addCourse() async {
    if (courseCode.text.trim().isEmpty || courseName.text.trim().isEmpty) {
      say('Enter code and name.');
      return;
    }
    await run(() async {
      final subjectId =
          await db.insertSubject(courseCode.text.trim(), courseName.text.trim());
      // Every course gets one section so lectures can attach to it.
      await db.insertSection(subjectId, '1', 'First', '2026-2027');
    }, 'Course added');
    courseCode.clear();
    courseName.clear();
  }

  Future<void> addLecture() async {
    if (lectureCourseId == null) {
      say('Choose a course.');
      return;
    }
    await run(
      () => db.insertLecture(lectureCourseId!, lectureDate.text.trim(),
          startTime.text.trim(), endTime.text.trim(), ''),
      'Lecture added',
    );
  }

  Future<void> saveAttendance() async {
    if (attendanceLectureId == null) {
      say('Choose a lecture.');
      return;
    }
    final lecture = lectures.firstWhere((l) => l['id'] == attendanceLectureId);
    final sectionId = lecture['section_id'] as int;

    await run(() async {
      for (final s in students) {
        try {
          await db.enrollStudent(s['id'] as int, sectionId);
        } catch (e) {
          // Already enrolled is fine; anything else is a real error.
          if (!e.toString().contains('UNIQUE')) rethrow;
        }
      }
      await db.saveAttendance(attendanceLectureId!, status);
    }, 'Attendance saved');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('ADD STUDENT'),
          TextField(
              controller: studentNumber,
              decoration: const InputDecoration(labelText: 'University number')),
          TextField(
              controller: studentName,
              decoration: const InputDecoration(labelText: 'Name')),
          ElevatedButton(onPressed: addStudent, child: const Text('Add student')),
          for (final s in students) Text('${s['student_number']}  ${s['full_name']}'),
          const Divider(),
          const Text('ADD COURSE'),
          TextField(
              controller: courseCode,
              decoration: const InputDecoration(labelText: 'Code')),
          TextField(
              controller: courseName,
              decoration: const InputDecoration(labelText: 'Name')),
          ElevatedButton(onPressed: addCourse, child: const Text('Add course')),
          for (final c in courses) Text('${c['subject_code']}  ${c['subject_name']}'),
          const Divider(),
          const Text('ADD LECTURE'),
          DropdownButton<int>(
            isExpanded: true,
            hint: const Text('Choose course'),
            value: lectureCourseId,
            items: [
              for (final c in courses)
                DropdownMenuItem(
                    value: c['id'] as int, child: Text('${c['subject_code']}')),
            ],
            onChanged: (v) => setState(() => lectureCourseId = v),
          ),
          TextField(
              controller: lectureDate,
              decoration: const InputDecoration(labelText: 'Date (yyyy-MM-dd)')),
          TextField(
              controller: startTime,
              decoration: const InputDecoration(labelText: 'Start (HH:mm)')),
          TextField(
              controller: endTime,
              decoration: const InputDecoration(labelText: 'End (HH:mm)')),
          ElevatedButton(onPressed: addLecture, child: const Text('Add lecture')),
          const Divider(),
          const Text('MARK ATTENDANCE'),
          DropdownButton<int>(
            isExpanded: true,
            hint: const Text('Choose lecture'),
            value: attendanceLectureId,
            items: [
              for (final l in lectures)
                DropdownMenuItem(
                  value: l['id'] as int,
                  child: Text(
                      '${l['subject_code']}  ${l['lecture_date']}  ${l['start_time']}'),
                ),
            ],
            onChanged: (v) => setState(() => attendanceLectureId = v),
          ),
          for (final s in students)
            Row(
              children: [
                Expanded(child: Text('${s['full_name']}')),
                DropdownButton<String>(
                  value: status[s['id'] as int],
                  items: [
                    for (final st in statuses)
                      DropdownMenuItem(value: st, child: Text(st)),
                  ],
                  onChanged: (v) => setState(() => status[s['id'] as int] = v!),
                ),
              ],
            ),
          ElevatedButton(onPressed: saveAttendance, child: const Text('Save attendance')),
        ],
      ),
    );
  }
}