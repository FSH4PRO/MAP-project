import 'package:final_project/database/database_helper.dart';
import 'package:final_project/database/instructor_dao.dart';
import 'package:final_project/database/user_dao.dart';
import 'package:final_project/errors/app_exception.dart';
import 'package:final_project/models/enums.dart';
import 'package:final_project/models/user.dart';
import 'package:final_project/services/auth_service.dart';
import 'package:final_project/services/session_context.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  const hasher = PasswordHasher(iterations: 100);
  late DatabaseHelper db;
  late UserDao users;
  late SessionContext session;
  late AuthService auth;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    db = DatabaseHelper.forTesting(); // in-memory, fresh per test
    users = UserDao(db);
    session = SessionContext();
    auth = AuthService(
      userDao: users,
      instructorDao: InstructorDao(db),
      db: db,
      session: session,
      hasher: hasher,
    );
  });

  tearDown(() async => (await db.database).close());

  Future<void> firstAdmin() => auth.createFirstAdmin(
        fullName: 'Admin',
        username: 'admin',
        password: 'secret1',
        confirmPassword: 'secret1',
      );

  test('first run is needed only while users is empty', () async {
    expect(await auth.needsFirstRun(), isTrue);
    await firstAdmin();
    expect(await auth.needsFirstRun(), isFalse);
    expect(firstAdmin, throwsA(isA<PermissionException>()));
  });

  test('first-run validation', () {
    expect(
        () => auth.createFirstAdmin(
            fullName: 'A', username: 'ab', password: 'secret1',
            confirmPassword: 'secret1'),
        throwsA(isA<ValidationException>()));
    expect(
        () => auth.createFirstAdmin(
            fullName: 'A', username: 'admin', password: '123',
            confirmPassword: '123'),
        throwsA(isA<ValidationException>()));
    expect(
        () => auth.createFirstAdmin(
            fullName: 'A', username: 'admin', password: 'secret1',
            confirmPassword: 'secret2'),
        throwsA(isA<ValidationException>()));
  });

  test('login ok is case-insensitive and fills the session', () async {
    await firstAdmin();
    await auth.login('ADMIN', 'secret1');
    expect(session.isLoggedIn, isTrue);
    expect(session.role, UserRole.admin);
  });

  test('wrong password / unknown user give the same message', () async {
    await firstAdmin();
    Future<String> messageOf(String u, String p) async {
      try {
        await auth.login(u, p);
      } on ValidationException catch (e) {
        return e.message;
      }
      fail('login should have failed');
    }

    final a = await messageOf('admin', 'wrong-pass');
    final b = await messageOf('ghost', 'secret1');
    expect(a, b);
    expect(session.isLoggedIn, isFalse);
  });

  test('empty fields are rejected', () async {
    expect(() => auth.login('', 'x'), throwsA(isA<ValidationException>()));
    expect(() => auth.login('admin', ''), throwsA(isA<ValidationException>()));
  });

  test('inactive user cannot log in', () async {
    await users.insert(User(
      username: 'old',
      passwordHash: hasher.hash('secret1'),
      fullName: 'Old',
      role: UserRole.registrar,
      isActive: false,
    ));
    expect(() => auth.login('old', 'secret1'),
        throwsA(isA<ValidationException>()));
  });

  test('instructor login loads instructorId', () async {
    final uid = await users.insert(User(
      username: 'inst',
      passwordHash: hasher.hash('secret1'),
      fullName: 'Inst',
      role: UserRole.instructor,
    ));
    final raw = await db.database;
    final iid = await raw.insert('instructors', {'user_id': uid});
    await auth.login('inst', 'secret1');
    expect(session.instructorId, iid);
  });

  test('instructor user without instructors row is refused', () async {
    await users.insert(User(
      username: 'inst',
      passwordHash: hasher.hash('secret1'),
      fullName: 'Inst',
      role: UserRole.instructor,
    ));
    expect(() => auth.login('inst', 'secret1'),
        throwsA(isA<ConflictException>()));
    expect(session.isLoggedIn, isFalse);
  });

  test('change password', () async {
    await firstAdmin();
    await auth.login('admin', 'secret1');
    expect(
        () => auth.changePassword(
            currentPassword: 'bad', newPassword: 'newpass1',
            confirmPassword: 'newpass1'),
        throwsA(isA<ValidationException>()));
    await auth.changePassword(
        currentPassword: 'secret1', newPassword: 'newpass1',
        confirmPassword: 'newpass1');
    auth.logout();
    expect(() => auth.login('admin', 'secret1'),
        throwsA(isA<ValidationException>()));
    await auth.login('admin', 'newpass1');
    expect(session.isLoggedIn, isTrue);
  });

  test('change password requires a session', () {
    expect(
        () => auth.changePassword(
            currentPassword: 'a', newPassword: 'newpass1',
            confirmPassword: 'newpass1'),
        throwsA(isA<PermissionException>()));
  });

  test('logout clears the session', () async {
    await firstAdmin();
    await auth.login('admin', 'secret1');
    auth.logout();
    expect(session.isLoggedIn, isFalse);
  });
}
