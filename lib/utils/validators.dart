String? required(String? value, [String message = 'هذا الحقل مطلوب']) {
  if (value == null || value.trim().isEmpty) {
    return message;
  }
  return null;
}

String? minLength(String? value, int min, [String? label]) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  if (text.length < min) {
    final name = label ?? 'القيمة';
    return '$name يجب أن يكون طوله على الأقل $min أحرف';
  }
  return null;
}

String? maxLength(String? value, int max, [String? label]) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  if (text.length > max) {
    final name = label ?? 'القيمة';
    return '$name يجب أن يكون طوله أقل من أو يساوي $max حرفاً';
  }
  return null;
}

String? email(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
    return 'البريد الإلكتروني غير صالح';
  }
  return null;
}

String? phone(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;

  final cleaned = text.replaceAll(RegExp(r'[^0-9+]'), '');
  final digits = cleaned.replaceAll('+', '');
  if (cleaned.length < 7 || cleaned.length > 15 || digits.length < 7 || digits.length > 15) {
    return 'رقم الهاتف يجب أن يحتوي بين 7 و15 رقمًا';
  }
  if (!RegExp(r'^[+0-9 ]+$').hasMatch(text)) {
    return 'رقم الهاتف يحتوي أحرفاً غير مسموح بها';
  }
  return null;
}

String? username(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'اسم المستخدم مطلوب';
  if (RegExp(r'\s').hasMatch(text)) {
    return 'اسم المستخدم يجب ألا يحتوي مسافات';
  }
  if (text.length < 3 || text.length > 30) {
    return 'اسم المستخدم من 3 إلى 30 حرفاً';
  }
  return null;
}

String? positiveInt(dynamic value, [String? label]) {
  final name = label ?? 'القيمة';
  if (value == null) {
    return '$name مطلوبة';
  }

  final parsed = value is int ? value : int.tryParse(value.toString().trim());
  if (parsed == null || parsed < 1) {
    return '$name يجب أن تكون قيمة صحيحة أكبر من صفر';
  }
  return null;
}

String? yearRange(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final year = int.tryParse(text);
  if (year == null || year < 1900 || year > 2100) {
    return 'السنة غير صالحة';
  }
  return null;
}

String? studentNumber(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'رقم الطالب مطلوب';
  if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(text)) {
    return 'رقم الطالب يسمح بأحرف وأرقام فقط';
  }
  return null;
}

String? subjectCode(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'رمز المادة مطلوب';
  if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(text)) {
    return 'رمز المادة يسمح بأحرف وأرقام وـ فقط';
  }
  return null;
}

String? blankToNull(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? null : text;
}
