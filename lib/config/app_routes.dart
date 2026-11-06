import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/auth/first_run_setup_screen.dart';
import '../screens/auth/login_screen.dart';
import '../services/session_context.dart';
import '../widgets/unauthorized_view.dart';
import 'permissions.dart';

/// Access rule of one route. Every route MUST pick one constructor, so a
/// forgotten rule is a compile error, not an open door (fail-closed).
class _RouteDef {
  const _RouteDef.public(this.builder)
      : permission = null,
        publicRoute = true;
  const _RouteDef.anyUser(this.builder)
      : permission = null,
        publicRoute = false;
  const _RouteDef.requires(this.permission, this.builder) : publicRoute = false;

  final WidgetBuilder builder;
  final Permission? permission;
  final bool publicRoute;
}

class AppRoutes {
  static const login = '/login';
  static const firstRun = '/first-run';
  static const dashboard = '/dashboard';
  static const changePassword = '/change-password';
  // TODO(team): add the remaining route names from the plan (9.8) here.

  static final Map<String, _RouteDef> _routes = {
    login: _RouteDef.public((_) => const LoginScreen()),
    firstRun: _RouteDef.public((_) => const FirstRunSetupScreen()),
    changePassword: _RouteDef.anyUser((_) => const ChangePasswordScreen()),
    dashboard: _RouteDef.requires(
      Permission.viewDashboard,
      (_) => const _PlaceholderScreen('لوحة التحكم'),
    ),
    // Teammates: replace a placeholder by their screen, keep the permission.
  };

  /// The route guard (plan step 10).
  static Route<dynamic> onGenerateRoute(
      RouteSettings settings, SessionContext session) {
    final def = _routes[settings.name];
    if (def == null) {
      return _page(settings, (_) => const _PlaceholderScreen('الصفحة غير موجودة'));
    }
    if (def.publicRoute) return _page(settings, def.builder);

    if (!session.isLoggedIn) {
      return _page(const RouteSettings(name: login), _routes[login]!.builder);
    }
    final needed = def.permission;
    if (needed != null && !session.can(needed)) {
      return _page(settings, (_) => const UnauthorizedView());
    }
    return _page(settings, def.builder);
  }

  static MaterialPageRoute<dynamic> _page(
          RouteSettings settings, WidgetBuilder builder) =>
      MaterialPageRoute(settings: settings, builder: builder);
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionContext>().user;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'تغيير كلمة المرور',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.changePassword),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
            },
          ),
        ],
      ),
      body: Center(
        child: Text(user == null
            ? 'قيد الإنشاء'
            : 'مرحباً ${user.fullName} (${user.role.arabicLabel})'),
      ),
    );
  }
}
