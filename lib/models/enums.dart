/// Roles stored in users.user_type (must match the CHECK constraint).
enum UserRole {
  admin,
  registrar,
  instructor,
  supervisor;

  /// Value written to / read from the database.
  String get dbValue => name;

  String get arabicLabel => switch (this) {
        UserRole.admin => 'مدير النظام',
        UserRole.registrar => 'شؤون الطلاب',
        UserRole.instructor => 'مدرّس',
        UserRole.supervisor => 'مشرف',
      };

  static UserRole fromDb(String value) {
    for (final role in values) {
      if (role.name == value) return role;
    }
    throw ArgumentError.value(value, 'user_type', 'Unknown role');
  }
}
