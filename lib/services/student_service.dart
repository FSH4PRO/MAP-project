import '../config/permissions.dart';
import '../database/database_helper.dart';
import '../database/student_dao.dart';
import '../errors/app_exception.dart';
import '../models/student.dart';
import '../utils/validators.dart' as validators;
import 'session_context.dart';

class StudentService {
  StudentService({
    required StudentDao studentDao,
    required this._db,
    required this._session,
  }) : _students = studentDao;

  final StudentDao _students;
  final DatabaseHelper _db;
  final SessionContext _session;

  Future<List<Student>> listStudents({
    bool includeInactive = false,
    String? query,
  }) async {
    _session.require(Permission.viewStudents);
    try {
      return await _students.search(
        query ?? '',
        includeInactive: includeInactive,
      );
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<List<StudentEnrollment>> listStudentEnrollments(int studentId) async {
    _session.require(Permission.viewStudents);
    try {
      return await _students.findEnrollments(studentId);
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<List<StudentAttendance>> listStudentAttendance(int studentId) async {
    _session.require(Permission.viewStudents);
    try {
      return await _students.findAttendance(studentId);
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<Student> createStudent({
    required String studentNumber,
    required String fullName,
    String? email,
    String? phone,
    String? department,
    String? enrollmentYear,
    bool isActive = true,
  }) async {
    _session.require(Permission.manageStudents);

    final error =
        validators.required(studentNumber, 'رقم الطالب مطلوب') ??
        validators.studentNumber(studentNumber) ??
        validators.required(fullName, 'اسم الطالب مطلوب') ??
        validators.email(email) ??
        validators.phone(phone) ??
        validators.yearRange(enrollmentYear);

    if (error != null) {
      throw ValidationException(error);
    }

    final sanitizedStudentNumber = studentNumber.trim();
    final cleanEmail = validators.blankToNull(email)?.trim();
    final cleanPhone = validators.blankToNull(phone)?.trim();
    final cleanedDepartment = validators.blankToNull(department)?.trim();
    final finalYear = enrollmentYear == null || enrollmentYear.trim().isEmpty
        ? null
        : int.tryParse(enrollmentYear.trim());

    final student = Student(
      studentNumber: sanitizedStudentNumber,
      fullName: fullName.trim(),
      email: cleanEmail,
      phone: cleanPhone,
      department: cleanedDepartment,
      enrollmentYear: finalYear,
      isActive: isActive,
    );

    try {
      return await _db.runInTransaction<Student>((txn) async {
        final existingNumber = await _students.findByNumber(
          sanitizedStudentNumber,
          executor: txn,
        );
        if (existingNumber != null) {
          throw const ConflictException('رقم الطالب مستخدم مسبقاً');
        }
        if (cleanEmail != null) {
          final existingEmail = await _students.findByEmail(
            cleanEmail,
            executor: txn,
          );
          if (existingEmail != null) {
            throw const ConflictException('البريد الإلكتروني مستخدم مسبقاً');
          }
        }

        final id = await _students.insert(student, executor: txn);
        return student.copyWith(id: id);
      });
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<Student> updateStudent({
    required int id,
    required String studentNumber,
    required String fullName,
    String? email,
    String? phone,
    String? department,
    String? enrollmentYear,
    bool? isActive,
  }) async {
    _session.require(Permission.manageStudents);

    final error =
        validators.required(studentNumber, 'رقم الطالب مطلوب') ??
        validators.studentNumber(studentNumber) ??
        validators.required(fullName, 'اسم الطالب مطلوب') ??
        validators.email(email) ??
        validators.phone(phone) ??
        validators.yearRange(enrollmentYear);

    if (error != null) {
      throw ValidationException(error);
    }

    final current = await _students.findById(id);
    if (current == null) {
      throw const NotFoundException('الطالب غير موجود');
    }

    final cleanEmail = validators.blankToNull(email)?.trim();
    final cleanPhone = validators.blankToNull(phone)?.trim();
    final cleanedDepartment = validators.blankToNull(department)?.trim();
    final cleanYear = enrollmentYear == null || enrollmentYear.trim().isEmpty
        ? null
        : int.tryParse(enrollmentYear.trim());

    final updated = Student(
      id: current.id,
      studentNumber: studentNumber.trim(),
      fullName: fullName.trim(),
      email: cleanEmail,
      phone: cleanPhone,
      department: cleanedDepartment,
      enrollmentYear: cleanYear,
      isActive: isActive ?? current.isActive,
      createdAt: current.createdAt,
    );

    try {
      return await _db.runInTransaction<Student>((txn) async {
        if (current.studentNumber.toLowerCase() !=
            updated.studentNumber.toLowerCase()) {
          final existing = await _students.findByNumber(
            updated.studentNumber,
            executor: txn,
          );
          if (existing != null && existing.id != id) {
            throw const ConflictException('رقم الطالب مستخدم مسبقاً');
          }
        }
        if (cleanEmail != null &&
            current.email?.toLowerCase() != cleanEmail.toLowerCase()) {
          final existingEmail = await _students.findByEmail(
            cleanEmail,
            excludeStudentId: id,
            executor: txn,
          );
          if (existingEmail != null) {
            throw const ConflictException('البريد الإلكتروني مستخدم مسبقاً');
          }
        }
        await _students.update(updated, executor: txn);
        return updated;
      });
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<void> setActive(int studentId, bool active) async {
    _session.require(Permission.manageStudents);
    final existing = await _students.findById(studentId);
    if (existing == null) {
      throw const NotFoundException('الطالب غير موجود');
    }
    try {
      await _students.setActive(studentId, active);
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<void> deleteStudent(int studentId) async {
    _session.require(Permission.manageStudents);
    final existing = await _students.findById(studentId);
    if (existing == null) {
      throw const NotFoundException('الطالب غير موجود');
    }
    try {
      final hasRows = await _students.hasRelatedRows(studentId);
      if (hasRows) {
        await _students.setActive(studentId, false);
        throw const ValidationException(
          'لا يمكن حذف الطالب لأن لديه سجلات في التسجيل أو الحضور. تم تعطيله فقط.',
        );
      }
      await _students.deleteById(studentId);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw DbErrors.translate(e);
    }
  }
}
