import 'package:sqflite/sqflite.dart' show DatabaseExecutor;

import '../config/permissions.dart';
import '../database/database_helper.dart';
import '../database/user_dao.dart';
import '../errors/app_exception.dart';
import '../models/enums.dart';
import '../models/user.dart';
import 'auth_service.dart' show PasswordHasher;
import 'session_context.dart';
import 'user_rules.dart';

/// Username / email uniqueness checks shared by [UserService] and
/// InstructorService. Run them INSIDE the transaction that writes the row.
class UserUniqueness {
  /// The schema's UNIQUE(username) is case-sensitive and email has no UNIQUE,
  /// so both are checked here, case-insensitively.
  static Future<void> ensureFree(
    UserDao users,
    DatabaseExecutor txn, {
    required String username,
    String? email,
    int? excludeUserId,
  }) async {
    final byName = await users.findByUsername(username, executor: txn);
    if (byName != null && byName.id != excludeUserId) {
      throw const ConflictException('اسم المستخدم مستخدم مسبقاً');
    }
    if (email != null) {
      final byEmail = await users.findByEmail(
        email,
        excludeUserId: excludeUserId,
        executor: txn,
      );
      if (byEmail != null) {
        throw const ConflictException('البريد الإلكتروني مستخدم مسبقاً');
      }
    }
  }
}

/// FR3 (add user) + activate/deactivate. Admin only. Users are never deleted.
/// Instructor accounts are NOT created here: they need an `instructors` row
/// too, so they go through InstructorService (one transaction).
class UserService {
  UserService({
    required UserDao userDao,
    required DatabaseHelper db,
    required SessionContext session,
    PasswordHasher hasher = const PasswordHasher(),
  }) : _users = userDao,
       _db = db,
       _session = session,
       _hasher = hasher;

  final UserDao _users;
  final DatabaseHelper _db;
  final SessionContext _session;
  final PasswordHasher _hasher;

  Future<List<User>> listUsers() async {
    _session.require(Permission.manageUsers);
    try {
      return await _users.findAll();
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<User> createUser({
    required String fullName,
    required String username,
    required String password,
    required String confirmPassword,
    required UserRole role,
    String? email,
    bool isActive = true,
  }) async {
    _session.require(Permission.manageUsers);
    if (role == UserRole.instructor) {
      throw const ValidationException('أنشئ المدرّس من شاشة المدرّسين');
    }
    final error =
        UserRules.fullName(fullName) ??
        UserRules.username(username) ??
        UserRules.email(email) ??
        UserRules.password(password) ??
        UserRules.confirm(password, confirmPassword);
    if (error != null) throw ValidationException(error);

    final cleanEmail = UserRules.blankToNull(email);
    final hash = _hasher.hash(password); // slow on purpose; outside the txn
    try {
      return await _db.runInTransaction<User>((txn) async {
        await UserUniqueness.ensureFree(
          _users,
          txn,
          username: username.trim(),
          email: cleanEmail,
        );
        final user = User(
          username: username.trim(),
          passwordHash: hash,
          fullName: fullName.trim(),
          email: cleanEmail,
          role: role,
          isActive: isActive,
        );
        final id = await _users.insert(user, executor: txn);
        return user.copyWith(id: id);
      });
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<void> setActive(int userId, bool active) async {
    _session.require(Permission.manageUsers);
    if (!active && userId == _session.user?.id) {
      // Also guarantees at least one active admin keeps the system usable.
      throw const ValidationException('لا يمكنك تعطيل حسابك الخاص');
    }
    try {
      if (await _users.findById(userId) == null) {
        throw const NotFoundException('الحساب غير موجود');
      }
      await _users.setActive(userId, active);
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }
}
