/// Shared field rules (used by forms AND services). Return null when valid.
class UserRules {
  static const minPasswordLength = 6;
  static const minUsernameLength = 3;
  static const maxUsernameLength = 30;
  static const maxEmployeeNumberLength = 30;

  static String? fullName(String? v) =>
      (v == null || v.trim().isEmpty) ? 'الاسم الكامل مطلوب' : null;

  static String? username(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'اسم المستخدم مطلوب';
    if (RegExp(r'\s').hasMatch(s)) return 'اسم المستخدم يجب ألا يحتوي مسافات';
    if (s.length < minUsernameLength || s.length > maxUsernameLength) {
      return 'اسم المستخدم من $minUsernameLength إلى $maxUsernameLength حرفاً';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
    if (v.length < minPasswordLength) {
      return 'كلمة المرور $minPasswordLength أحرف على الأقل';
    }
    return null;
  }

  /// Optional field: empty is valid. Needs one @ with text around it and a
  /// dot after it; no spaces.
  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s)) {
      return 'البريد الإلكتروني غير صالح';
    }
    return null;
  }

  /// Optional field: empty is valid.
  static String? employeeNumber(String? v) {
    final s = v?.trim() ?? '';
    if (s.length > maxEmployeeNumberLength) {
      return 'رقم الموظف طويل جداً (الحد $maxEmployeeNumberLength)';
    }
    return null;
  }

  /// Trims; blank becomes null so optional UNIQUE columns store NULL, not ''.
  /// (SQLite allows many NULLs in a UNIQUE column, but only one '').
  static String? blankToNull(String? v) {
    final s = v?.trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static String? confirm(String? password, String? confirm) =>
      password == confirm ? null : 'كلمتا المرور غير متطابقتين';
}
