import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_routes.dart';
import '../config/permissions.dart';
import '../services/session_context.dart';
import '../utils/app_strings.dart';
import 'app_bar_actions.dart';

class _Entry {
  const _Entry(this.route, this.label, this.icon, this.permission);
  final String route;
  final String label;
  final IconData icon;
  final Permission permission;
}

/// Side drawer with a link to every module the current role may open.
/// Hiding a link is only convenience: the route guard is the real check.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const List<_Entry> _entries = [
    _Entry(
      AppRoutes.dashboard,
      AppStrings.dashboard,
      Icons.dashboard,
      Permission.viewDashboard,
    ),
    _Entry(
      AppRoutes.users,
      AppStrings.users,
      Icons.manage_accounts,
      Permission.manageUsers,
    ),
    _Entry(
      AppRoutes.students,
      AppStrings.students,
      Icons.groups,
      Permission.viewStudents,
    ),
    _Entry(
      AppRoutes.instructors,
      AppStrings.instructors,
      Icons.badge,
      Permission.viewInstructors,
    ),
    _Entry(
      AppRoutes.subjects,
      AppStrings.subjects,
      Icons.menu_book,
      Permission.manageSubjects,
    ),
    _Entry(
      AppRoutes.sections,
      AppStrings.sections,
      Icons.view_list,
      Permission.manageSections,
    ),
    _Entry(
      AppRoutes.enrollments,
      AppStrings.enrollments,
      Icons.how_to_reg,
      Permission.manageEnrollments,
    ),
    _Entry(
      AppRoutes.lectures,
      AppStrings.lectures,
      Icons.event,
      Permission.viewLectures,
    ),
    _Entry(
      AppRoutes.selectLecture,
      AppStrings.takeAttendance,
      Icons.fact_check,
      Permission.recordAttendance,
    ),
    _Entry(
      AppRoutes.attendanceHistory,
      AppStrings.attendanceHistory,
      Icons.history,
      Permission.viewAttendance,
    ),
    _Entry(
      AppRoutes.attendanceReport,
      AppStrings.attendanceReport,
      Icons.bar_chart,
      Permission.viewReports,
    ),
    _Entry(
      AppRoutes.studentReport,
      AppStrings.studentReport,
      Icons.person_search,
      Permission.viewReports,
    ),
  ];

  void _open(BuildContext context, String route) {
    final nav = Navigator.of(context);
    nav.pop(); // close the drawer
    if (ModalRoute.of(context)?.settings.name == route) return;
    if (route == AppRoutes.dashboard) {
      nav.pushNamedAndRemoveUntil(route, (_) => false);
    } else {
      // Keep the dashboard at the bottom so Back always leads there.
      nav.pushNamedAndRemoveUntil(
        route,
        (r) => r.settings.name == AppRoutes.dashboard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionContext>();
    final user = session.user;
    final current = ModalRoute.of(context)?.settings.name;
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: scheme.primary),
              currentAccountPicture: CircleAvatar(
                backgroundColor: scheme.onPrimary,
                child: Icon(Icons.person, color: scheme.primary),
              ),
              accountName: Text(user?.fullName ?? ''),
              accountEmail: Text(user?.role.arabicLabel ?? ''),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final e in _entries)
                    if (session.can(e.permission))
                      ListTile(
                        leading: Icon(e.icon),
                        title: Text(e.label),
                        selected: current == e.route,
                        onTap: () => _open(context, e.route),
                      ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.key),
              title: const Text(AppStrings.changePassword),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.changePassword);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(AppStrings.logout),
              onTap: () => AppBarActions.logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
