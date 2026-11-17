import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../config/app_config.dart';
import '../database/database_helper.dart';
import '../database/instructor_dao.dart';
import '../database/user_dao.dart';
import '../errors/app_exception.dart';
import '../models/enums.dart';
import '../models/user.dart';
import 'session_context.dart';
import 'user_rules.dart';

/// Stored format: iterations$salt$hash (salt, hash = base64).
/// hash_0 = SHA256(salt || pwd); hash_i = SHA256(hash_{i-1} || pwd).
class PasswordHasher {
  const PasswordHasher({this.iterations = AppConfig.passwordHashIterations});
  final int iterations;

  /// Upper bound so a tampered DB value cannot freeze the app.
  static const _maxIterations = 1000000;

  String hash(String password) {
    final rng = Random.secure();
    final salt = List<int>.generate(16, (_) => rng.nextInt(256));
    final digest = _derive(password, salt, iterations);
    return [iterations, base64.encode(salt), base64.encode(digest)].join(r'$');
  }

  bool verify(String password, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 3) return false;
    final iters = int.tryParse(parts[0]);
    if (iters == null || iters < 1 || iters > _maxIterations) return false;
    final List<int> salt;
    final List<int> expected;
    try {
      salt = base64.decode(parts[1]);
      expected = base64.decode(parts[2]);
    } on FormatException {
      return false;
    }
    return _constantTimeEquals(_derive(password, salt, iters), expected);
  }

  List<int> _derive(String password, List<int> salt, int iters) {
    final pwd = utf8.encode(password);
    var digest = sha256.convert([...salt, ...pwd]).bytes;
    for (var i = 1; i < iters; i++) {
      digest = sha256.convert([...digest, ...pwd]).bytes;
    }
    return digest;
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// FR1, FR2, FR4, FR5 + first-run admin creation. No Flutter imports.
class AuthService {
  AuthService({
    required UserDao userDao,
    required InstructorDao instructorDao,
    required this._db,
    required this._session,
    this._hasher = const PasswordHasher(),
  })  : _users = userDao,
        _instructors = instructorDao;

  final UserDao _users;
  final InstructorDao _instructors;
  final DatabaseHelper _db;
  final SessionContext _session;
  final PasswordHasher _hasher;

  static const _badCredentials = 'اسم المستخدم أو كلمة المرور غير صحيحة';

  /// Verified against when the username does not exist, so response time
  /// does not reveal whether the username is real.
  late final String _dummyHash = _hasher.hash('not-a-real-password');

  Future<bool> needsFirstRun() async {
    try {
      return await _users.count() == 0;
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  /// Works only while `users` is empty; check + insert share one transaction.
  Future<User> createFirstAdmin({
    required String fullName,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    final error = UserRules.fullName(fullName) ??
        UserRules.username(username) ??
        UserRules.password(password) ??
        UserRules.confirm(password, confirmPassword);
    if (error != null) throw ValidationException(error);

    final hash = _hasher.hash(password);
    try {
      return await _db.runInTransaction<User>((txn) async {
        if (await _users.count(executor: txn) > 0) {
          throw const PermissionException('تم إعداد النظام مسبقاً');
        }
        final user = User(
          username: username.trim(),
          passwordHash: hash,
          fullName: fullName.trim(),
          role: UserRole.admin,
        );
        final id = await _users.insert(user, executor: txn);
        return user.copyWith(id: id);
      });
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<User> login(String username, String password) async {
    final name = username.trim();
    if (name.isEmpty || password.isEmpty) {
      throw const ValidationException('أدخل اسم المستخدم وكلمة المرور');
    }
    try {
      final user = await _users.findByUsername(name);
      final passwordOk =
          _hasher.verify(password, user?.passwordHash ?? _dummyHash);
      if (user == null || !user.isActive || !passwordOk) {
        throw const ValidationException(_badCredentials);
      }

      int? instructorId;
      if (user.role == UserRole.instructor) {
        instructorId = await _instructors.findIdByUserId(user.id!);
        if (instructorId == null) {
          throw const ConflictException('حساب المدرّس غير مكتمل، راجع المسؤول');
        }
      }
      _session.start(user, instructorId: instructorId);
      return user;
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  void logout() => _session.clear();

  /// FR5: a user changes his OWN password only (id comes from the session).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final sessionUser = _session.user;
    if (sessionUser == null) {
      throw const PermissionException('يجب تسجيل الدخول أولاً');
    }
    final error = UserRules.password(newPassword) ??
        UserRules.confirm(newPassword, confirmPassword);
    if (error != null) throw ValidationException(error);

    try {
      final fresh = await _users.findById(sessionUser.id!);
      if (fresh == null || !fresh.isActive) {
        throw const NotFoundException('الحساب غير موجود');
      }
      if (!_hasher.verify(currentPassword, fresh.passwordHash)) {
        throw const ValidationException('كلمة المرور الحالية غير صحيحة');
      }
      if (currentPassword == newPassword) {
        throw const ValidationException('كلمة المرور الجديدة مطابقة للحالية');
      }
      final newHash = _hasher.hash(newPassword);
      await _users.updatePasswordHash(fresh.id!, newHash);
      _session.updateUser(fresh.copyWith(passwordHash: newHash));
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }
}
