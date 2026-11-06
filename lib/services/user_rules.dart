/// Shared field rules (used by forms AND services). Return null when valid.
class UserRules {
  static const minPasswordLength = 6;
  static const minUsernameLength = 3;
  static const maxUsernameLength = 30;

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

  static String? confirm(String? password, String? confirm) =>
      password == confirm ? null : 'كلمتا المرور غير متطابقتين';
}
