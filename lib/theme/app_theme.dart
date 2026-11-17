import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'app_colors.dart';

/// One visual identity for the whole app (Material 3, bundled Arabic font).
class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppConfig.fontFamily,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
