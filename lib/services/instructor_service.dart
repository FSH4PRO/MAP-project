import '../config/permissions.dart';
import '../database/database_helper.dart';
import '../database/instructor_dao.dart';
import '../database/user_dao.dart';
import '../errors/app_exception.dart';
import '../models/enums.dart';
import '../models/instructor.dart';
import '../models/user.dart';
import 'auth_service.dart' show PasswordHasher;
import 'session_context.dart';
import 'user_rules.dart';
import 'user_service.dart' show UserUniqueness;

/// FR12: add / edit / list instructors. No Flutter imports.
class InstructorService {
  InstructorService({
    required UserDao userDao,
    required InstructorDao instructorDao,
    required DatabaseHelper db,
    required SessionContext session,
    PasswordHasher hasher = const PasswordHasher(),
  }) : _users = userDao,
       _instructors = instructorDao,
       _db = db,
       _session = session,
       _hasher = hasher;

  final UserDao _users;
  final InstructorDao _instructors;
  final DatabaseHelper _db;
  final SessionContext _session;
  final PasswordHasher _hasher;

  static const _duplicateEmployee = 'رقم الموظف مستخدم مسبقاً';

  Future<List<InstructorInfo>> listInstructors() async {
    _session.require(Permission.viewInstructors);
    try {
      return await _instructors.findAllInfo();
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  /// ONE transaction: users row (type instructor) + instructors row.
  /// If the second insert fails (e.g. duplicate employee number) the user row
  /// is rolled back too, so no half-created instructor can exist.
  Future<InstructorInfo> createInstructor({
    required String fullName,
    required String username,
    required String password,
    required String confirmPassword,
    String? email,
    String? employeeNumber,
    String? specialization,
  }) async {
    // Creating an instructor also creates a login account.
    _session.require(Permission.manageInstructors);
    _session.require(Permission.manageUsers);
    final error =
        UserRules.fullName(fullName) ??
        UserRules.username(username) ??
        UserRules.email(email) ??
        UserRules.employeeNumber(employeeNumber) ??
        UserRules.password(password) ??
        UserRules.confirm(password, confirmPassword);
    if (error != null) throw ValidationException(error);

    final cleanEmail = UserRules.blankToNull(email);
    final hash = _hasher.hash(password);
    try {
      return await _db.runInTransaction<InstructorInfo>((txn) async {
        await UserUniqueness.ensureFree(
          _users,
          txn,
          username: username.trim(),
          email: cleanEmail,
        );
        final userId = await _users.insert(
          User(
            username: username.trim(),
            passwordHash: hash,
            fullName: fullName.trim(),
            email: cleanEmail,
            role: UserRole.instructor,
          ),
          executor: txn,
        );
        int instructorId;
        try {
          instructorId = await _instructors.insert(
            Instructor(
              userId: userId,
              employeeNumber: UserRules.blankToNull(employeeNumber),
              specialization: UserRules.blankToNull(specialization),
            ),
            executor: txn,
          );
        } catch (e) {
          if (DbErrors.isUnique(e)) {
            throw const ConflictException(_duplicateEmployee);
          }
          rethrow;
        }
        return (await _instructors.findInfoById(instructorId, executor: txn))!;
      });
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  /// Edits name/email (users) and employee number/specialization
  /// (instructors) together; username and password are not changed here.
  Future<InstructorInfo> updateInstructor({
    required int instructorId,
    required String fullName,
    String? email,
    String? employeeNumber,
    String? specialization,
  }) async {
    _session.require(Permission.manageInstructors);
    final error =
        UserRules.fullName(fullName) ??
        UserRules.email(email) ??
        UserRules.employeeNumber(employeeNumber);
    if (error != null) throw ValidationException(error);

    final cleanEmail = UserRules.blankToNull(email);
    try {
      return await _db.runInTransaction<InstructorInfo>((txn) async {
        final current = await _instructors.findInfoById(
          instructorId,
          executor: txn,
        );
        if (current == null) {
          throw const NotFoundException('المدرّس غير موجود');
        }
        await UserUniqueness.ensureFree(
          _users,
          txn,
          username: current.username,
          email: cleanEmail,
          excludeUserId: current.userId,
        );
        await _users.updateProfile(
          current.userId,
          fullName: fullName.trim(),
          email: cleanEmail,
          executor: txn,
        );
        try {
          await _instructors.updateDetails(
            instructorId,
            employeeNumber: UserRules.blankToNull(employeeNumber),
            specialization: UserRules.blankToNull(specialization),
            executor: txn,
          );
        } catch (e) {
          if (DbErrors.isUnique(e)) {
            throw const ConflictException(_duplicateEmployee);
          }
          rethrow;
        }
        return (await _instructors.findInfoById(instructorId, executor: txn))!;
      });
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }
}
