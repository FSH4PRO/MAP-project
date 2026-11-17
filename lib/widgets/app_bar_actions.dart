import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_routes.dart';
import '../providers/auth_provider.dart';
import '../utils/app_strings.dart';

/// The two icons every AppBar shows: change password and logout (FR4, FR5).
class AppBarActions {
  static List<Widget> of(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.key),
      tooltip: AppStrings.changePassword,
      onPressed: () =>
          Navigator.of(context).pushNamed(AppRoutes.changePassword),
    ),
    IconButton(
      icon: const Icon(Icons.logout),
      tooltip: AppStrings.logout,
      onPressed: () => logout(context),
    ),
  ];

  /// Clears the session, then drops the whole navigation stack.
  static Future<void> logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }
}
