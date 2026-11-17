/// Arabic UI strings shared by the shell and my screens.
/// (Screens written earlier still use inline literals; migrate when touched.)
class AppStrings {
  static const appName = 'نظام إدارة المحاضرات والحضور';

  // Common
  static const save = 'حفظ';
  static const cancel = 'إلغاء';
  static const retry = 'إعادة المحاولة';
  static const required = 'هذا الحقل مطلوب';
  static const active = 'فعّال';
  static const inactive = 'معطّل';
  static const noData = 'لا توجد بيانات';

  // Drawer / app bar
  static const changePassword = 'تغيير كلمة المرور';
  static const logout = 'تسجيل الخروج';

  // Menu labels
  static const dashboard = 'لوحة التحكم';
  static const users = 'المستخدمون';
  static const students = 'الطلاب';
  static const instructors = 'المدرّسون';
  static const subjects = 'المواد';
  static const sections = 'الشعب';
  static const enrollments = 'تسجيل الطلاب';
  static const lectures = 'المحاضرات';
  static const takeAttendance = 'تسجيل الحضور';
  static const attendanceHistory = 'سجل الحضور';
  static const attendanceReport = 'تقرير الحضور';
  static const studentReport = 'تقرير الطالب';

  // Users
  static const addUser = 'إضافة مستخدم';
  static const fullName = 'الاسم الكامل';
  static const username = 'اسم المستخدم';
  static const email = 'البريد الإلكتروني (اختياري)';
  static const password = 'كلمة المرور';
  static const confirmPassword = 'تأكيد كلمة المرور';
  static const role = 'الدور';
  static const accountActive = 'الحساب فعّال';
  static const userCreated = 'تمت إضافة المستخدم';
  static const confirmDeactivate =
      'تعطيل هذا الحساب؟ لن يتمكن من تسجيل الدخول.';
  static const confirmActivate = 'تفعيل هذا الحساب؟';

  // Instructors
  static const addInstructor = 'إضافة مدرّس';
  static const editInstructor = 'تعديل بيانات المدرّس';
  static const employeeNumber = 'رقم الموظف (اختياري)';
  static const specialization = 'التخصص (اختياري)';
  static const instructorSaved = 'تم حفظ بيانات المدرّس';

  // Errors / guard
  static const notFoundPage = 'الصفحة غير موجودة';
  static const underConstruction = 'قيد الإنشاء';
}
