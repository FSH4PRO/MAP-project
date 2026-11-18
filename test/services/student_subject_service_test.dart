import 'package:final_project/database/database_helper.dart';
import 'package:final_project/database/student_dao.dart';
import 'package:final_project/database/subject_dao.dart';
import 'package:final_project/errors/app_exception.dart';
import 'package:final_project/models/enums.dart';
import 'package:final_project/models/user.dart';
import 'package:final_project/services/session_context.dart';
import 'package:final_project/services/student_service.dart';
import 'package:final_project/services/subject_service.dart';
import 'package:final_project/utils/arabic_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper db;
  late SessionContext session;
  late StudentService students;
  late SubjectService subjects;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    db = DatabaseHelper.forTesting();
    session = SessionContext()
      ..start(
        const User(
          username: 'admin',
          passwordHash: 'hash',
          fullName: 'Admin',
          role: UserRole.admin,
        ),
      );
    students = StudentService(
      studentDao: StudentDao(db),
      db: db,
      session: session,
    );
    subjects = SubjectService(
      subjectDao: SubjectDao(db),
      db: db,
      session: session,
    );
  });

  tearDown(() async => db.close());

  Future<int> createEnrollment(int studentId, int subjectId) async {
    final raw = await db.database;
    final instructorUserId = await raw.insert('users', {
      'username': 'instructor$subjectId',
      'password_hash': 'hash',
      'full_name': 'Instructor',
      'user_type': 'instructor',
    });
    final instructorId = await raw.insert('instructors', {
      'user_id': instructorUserId,
    });
    final sectionId = await raw.insert('sections', {
      'subject_id': subjectId,
      'instructor_id': instructorId,
      'section_number': '01',
      'semester': 'الأول',
      'academic_year': '2026-2027',
    });
    return raw.insert('enrollments', {
      'student_id': studentId,
      'section_id': sectionId,
    });
  }

  test(
    'optional student values can be cleared and inactive state is preserved',
    () async {
      final student = await students.createStudent(
        studentNumber: 'S100',
        fullName: 'Student One',
        email: 'student@example.com',
        phone: '+963 900000000',
        department: 'Engineering',
        enrollmentYear: '2025',
      );
      await students.setActive(student.id!, false);

      await students.updateStudent(
        id: student.id!,
        studentNumber: student.studentNumber,
        fullName: student.fullName,
        email: '',
        phone: '',
        department: '',
        enrollmentYear: '',
      );

      final updated = await StudentDao(db).findById(student.id!);
      expect(updated!.email, isNull);
      expect(updated.phone, isNull);
      expect(updated.department, isNull);
      expect(updated.enrollmentYear, isNull);
      expect(updated.isActive, isFalse);
    },
  );

  test('student deletion removes unreferenced rows and deactivates referenced rows', () async {
    final deletable = await students.createStudent(
      studentNumber: 'S101',
      fullName: 'No Relations',
    );
    await students.deleteStudent(deletable.id!);
    expect(await StudentDao(db).findById(deletable.id!), isNull);

    final referenced = await students.createStudent(
      studentNumber: 'S102',
      fullName: 'Has Enrollment',
    );
    final subject = await subjects.createSubject(
      subjectCode: 'CS101',
      subjectName: 'Computer Science',
      creditHours: 3,
    );
    await createEnrollment(referenced.id!, subject.id!);

    await expectLater(
      students.deleteStudent(referenced.id!),
      throwsA(isA<ValidationException>()),
    );
    expect((await StudentDao(db).findById(referenced.id!))!.isActive, isFalse);
  });

  test(
    'subject department can be cleared and active state is preserved',
    () async {
      final subject = await subjects.createSubject(
        subjectCode: 'MATH1',
        subjectName: 'Mathematics',
        creditHours: 4,
        department: 'Science',
      );
      await subjects.setActive(subject.id!, false);
      await subjects.updateSubject(
        id: subject.id!,
        subjectCode: subject.subjectCode,
        subjectName: subject.subjectName,
        creditHours: subject.creditHours,
        department: '',
      );

      final updated = await SubjectDao(db).findById(subject.id!);
      expect(updated!.department, isNull);
      expect(updated.isActive, isFalse);
    },
  );

  test('student details include enrollments and attendance records', () async {
    final student = await students.createStudent(
      studentNumber: 'S103',
      fullName: 'Attendance Student',
    );
    final subject = await subjects.createSubject(
      subjectCode: 'CS102',
      subjectName: 'Databases',
      creditHours: 3,
    );
    await createEnrollment(student.id!, subject.id!);

    final raw = await db.database;
    final sectionId = (await raw.query('sections')).single['id'] as int;
    final lectureId = await raw.insert('lectures', {
      'section_id': sectionId,
      'lecture_date': '2026-11-17',
      'start_time': '09:00',
      'end_time': '10:00',
      'topic': 'SQL',
    });
    await raw.insert('attendance', {
      'lecture_id': lectureId,
      'student_id': student.id,
      'attendance_status': 'present',
    });

    final enrollmentRecords = await students.listStudentEnrollments(
      student.id!,
    );
    final attendanceRecords = await students.listStudentAttendance(student.id!);
    expect(enrollmentRecords, hasLength(1));
    expect(enrollmentRecords.single.subjectName, 'Databases');
    expect(attendanceRecords, hasLength(1));
    expect(attendanceRecords.single.status, 'present');
    expect(attendanceRecords.single.topic, 'SQL');
  });

  test('Arabic search normalization maps common letter variants', () {
    expect(normalizeArabic('إدارة الطّلبة'), normalizeArabic('اداره الطلبه'));
    expect(normalizeArabic('علي'), normalizeArabic('على'));
  });
}
