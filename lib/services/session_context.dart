import '../config/permissions.dart';
import '../errors/app_exception.dart';
import '../models/enums.dart';
import '../models/user.dart';

/// Holds the logged-in user. Plain Dart (no Flutter) so services can use it.
class SessionContext {
  User? _user;
  int? _instructorId;

  User? get user => _user;
  int? get instructorId => _instructorId;
  bool get isLoggedIn => _user != null;
  UserRole? get role => _user?.role;

  void start(User user, {int? instructorId}) {
    _user = user;
    _instructorId = instructorId;
  }

  void updateUser(User user) => _user = user;

  void clear() {
    _user = null;
    _instructorId = null;
  }

  bool can(Permission permission) {
    final r = role;
    return r != null && RolePermissions.has(r, permission);
  }

  /// Call at the top of every service write/read that is restricted.
  void require(Permission permission) {
    if (!isLoggedIn) {
      throw const PermissionException('يجب تسجيل الدخول أولاً');
    }
    if (!can(permission)) {
      throw const PermissionException('ليست لديك صلاحية لتنفيذ هذا الإجراء');
    }
  }

  /// Admin always passes; an instructor passes only for his own section.
  /// [sectionInstructorId] is sections.instructor_id of the target section.
  void requireOwnSection(int sectionInstructorId) {
    if (!isLoggedIn) {
      throw const PermissionException('يجب تسجيل الدخول أولاً');
    }
    if (role == UserRole.admin) return;
    if (role == UserRole.instructor && _instructorId == sectionInstructorId) {
      return;
    }
    throw const PermissionException('هذه الشعبة ليست من شعبك');
  }
}
