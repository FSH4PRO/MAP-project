/// App-wide technical settings (no UI strings, no colours).
class AppConfig {
  /// Bundled Arabic font family declared in pubspec.yaml.
  static const String fontFamily = 'Tajawal';

  /// The UI is Arabic (RTL). English is only a fallback locale.
  static const String localeCode = 'ar';

  /// SHA-256 rounds of the password hash (see PasswordHasher).
  static const int passwordHashIterations = 10000;
}
