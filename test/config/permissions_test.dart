import 'package:final_project/config/permissions.dart';
import 'package:final_project/errors/app_exception.dart';
import 'package:final_project/models/enums.dart';
import 'package:final_project/models/user.dart';
import 'package:final_project/services/session_context.dart';
import 'package:flutter_test/flutter_test.dart';

SessionContext sessionFor(UserRole role, {int? instructorId}) {
  final s = SessionContext();
  s.start(
    User(id: 1, username: 'u', passwordHash: 'x', fullName: 'U', role: role),
    instructorId: instructorId,
  );
  return s;
}

void main() {
  test('admin has every permission', () {
    for (final p in Permission.values) {
      expect(RolePermissions.has(UserRole.admin, p), isTrue, reason: '$p');
    }
  });

  test('supervisor is read-only', () {
    for (final p in [
      Permission.manageUsers,
      Permission.manageStudents,
      Permission.manageSubjects,
      Permission.manageSections,
      Permission.manageEnrollments,
      Permission.manageLectures,
      Permission.recordAttendance,
      Permission.editAttendance,
    ]) {
      expect(RolePermissions.has(UserRole.supervisor, p), isFalse, reason: '$p');
    }
    expect(RolePermissions.has(UserRole.supervisor, Permission.viewReports),
        isTrue);
  });

  test('only admin manages users', () {
    for (final r in UserRole.values) {
      expect(RolePermissions.has(r, Permission.manageUsers),
          r == UserRole.admin);
    }
  });

  test('only admin and instructor record attendance', () {
    for (final r in UserRole.values) {
      expect(RolePermissions.has(r, Permission.recordAttendance),
          r == UserRole.admin || r == UserRole.instructor);
    }
  });

  test('registrar manages academic data but cannot take attendance', () {
    expect(RolePermissions.has(UserRole.registrar, Permission.manageStudents),
        isTrue);
    expect(RolePermissions.has(UserRole.registrar, Permission.recordAttendance),
        isFalse);
  });

  group('SessionContext', () {
    test('require throws when logged out', () {
      expect(() => SessionContext().require(Permission.viewDashboard),
          throwsA(isA<PermissionException>()));
    });

    test('require passes / throws by role', () {
      final s = sessionFor(UserRole.supervisor);
      expect(() => s.require(Permission.viewReports), returnsNormally);
      expect(() => s.require(Permission.manageStudents),
          throwsA(isA<PermissionException>()));
    });

    test('requireOwnSection', () {
      expect(() => sessionFor(UserRole.admin).requireOwnSection(99),
          returnsNormally);
      expect(
          () => sessionFor(UserRole.instructor, instructorId: 5)
              .requireOwnSection(5),
          returnsNormally);
      expect(
          () => sessionFor(UserRole.instructor, instructorId: 5)
              .requireOwnSection(6),
          throwsA(isA<PermissionException>()));
      expect(() => sessionFor(UserRole.registrar).requireOwnSection(1),
          throwsA(isA<PermissionException>()));
    });

    test('clear logs out', () {
      final s = sessionFor(UserRole.admin)..clear();
      expect(s.isLoggedIn, isFalse);
      expect(s.instructorId, isNull);
    });
  });
}
