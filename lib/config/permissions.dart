import '../models/enums.dart';

/// Every guarded capability in the app.
enum Permission {
  viewDashboard,
  manageUsers,
  viewInstructors,
  manageInstructors,
  viewStudents,
  manageStudents,
  manageSubjects,
  manageSections,
  manageEnrollments,
  viewLectures,
  manageLectures,
  recordAttendance,
  editAttendance,
  viewAttendance,
  viewReports,
}

/// The ONLY place the role -> permission matrix lives.
class RolePermissions {
  static final Map<UserRole, Set<Permission>> _matrix = {
    UserRole.admin: Permission.values.toSet(),
    UserRole.registrar: {
      Permission.viewDashboard,
      Permission.viewInstructors,
      Permission.viewStudents,
      Permission.manageStudents,
      Permission.manageSubjects,
      Permission.manageSections,
      Permission.manageEnrollments,
      Permission.viewLectures,
      Permission.manageLectures,
      Permission.viewAttendance,
      Permission.viewReports,
    },
    UserRole.instructor: {
      Permission.viewDashboard,
      Permission.viewStudents,
      Permission.viewLectures,
      Permission.recordAttendance,
      Permission.editAttendance,
      Permission.viewAttendance,
      Permission.viewReports,
    },
    UserRole.supervisor: {
      Permission.viewDashboard,
      Permission.viewInstructors,
      Permission.viewStudents,
      Permission.viewLectures,
      Permission.viewAttendance,
      Permission.viewReports,
    },
  };

  static bool has(UserRole role, Permission permission) =>
      _matrix[role]?.contains(permission) ?? false;

  static Set<Permission> of(UserRole role) =>
      Set.unmodifiable(_matrix[role] ?? const <Permission>{});
}
