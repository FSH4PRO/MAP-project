import 'package:sqflite/sqflite.dart' show DatabaseException;

/// Base type for every error the UI is allowed to show.
/// [message] is Arabic and safe to display (never contains SQL).
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}

final class PermissionException extends AppException {
  const PermissionException(super.message);
}

final class ConflictException extends AppException {
  const ConflictException(super.message);
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

final class DatabaseFailure extends AppException {
  const DatabaseFailure(super.message);
}

/// Converts low-level sqflite errors into [AppException]s.
class DbErrors {
  static AppException translate(Object error) {
    if (error is AppException) return error;
    if (error is DatabaseException) {
      if (error.isUniqueConstraintError()) {
        return const ConflictException('القيمة موجودة مسبقاً');
      }
      if (error.isNotNullConstraintError()) {
        return const ValidationException('يوجد حقل مطلوب فارغ');
      }
      final text = error.toString();
      if (text.contains('FOREIGN KEY')) {
        return const ConflictException('السجل مرتبط ببيانات أخرى');
      }
      if (text.contains('CHECK constraint')) {
        return const ValidationException('قيمة غير مسموح بها');
      }
    }
    return const DatabaseFailure('حدث خطأ في قاعدة البيانات');
  }
}
