String normalizeArabic(String input) {
  if (input.isEmpty) return '';

  var value = input
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
      .toLowerCase();

  return value.trim();
}
