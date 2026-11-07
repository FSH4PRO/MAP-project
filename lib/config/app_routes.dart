import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/auth/change_password_screen.dart';
import '../screens/auth/first_run_setup_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/instructors/add_instructor_screen.dart';
import '../screens/instructors/instructors_list_screen.dart';
import '../screens/users/add_user_screen.dart';
import '../screens/users/users_list_screen.dart';
import '../services/session_context.dart';
import '../utils/app_strings.dart';
import '../widgets/app_bar_actions.dart';
import '../widgets/app_drawer.dart';
import '../widgets/unauthorized_view.dart';
import 'permissions.dart';

/// Access rule of one route. Every route MUST pick one constructor, so a
/// forgotten rule is a compile error, not an open door (fail-closed).
class _RouteDef {
  const _RouteDef.public(this.builder) : permission = null, publicRoute = true;
  const _RouteDef.anyUser(this.builder)
    : permission = null,
      publicRoute = false;
  const _RouteDef.requires(this.permission, this.builder) : publicRoute = false;

  final WidgetBuilder builder;
  final Permission? permission;
  final bool publicRoute;
}

/// Route names are a CONTRACT (contract-change PR, 4 approvals).
/// To build your screen: replace the `_placeholder(...)` builder of YOUR route
/// with your screen widget and KEEP the permission.
class AppRoutes {
  // Auth
  static const login = '/login';
  static const firstRun = '/first-run';
  static const changePassword = '/change-password';
  static const dashboard = '/dashboard';
  // Users (admin)
  static const users = '/users';
  static const addUser = '/users/add';
  // Students (Student 2)
  static const students = '/students';
  static const addStudent = '/students/add';
  static const studentDetails = '/students/details';
  // Instructors
  static const instructors = '/instructors';
  static const addInstructor = '/instructors/add';
  // Subjects (Student 2)
  static const subjects = '/subjects';
  static const addSubject = '/subjects/add';
  // Sections and lectures (Student 3)
  static const sections = '/sections';
  static const enrollments = '/sections/enrollments';
  static const lectures = '/lectures';
  static const addLecture = '/lectures/add';
  // Attendance and reports (Student 4)
  static const selectLecture = '/attendance/select';
  static const takeAttendance = '/attendance/take';
  static const attendanceHistory = '/attendance/history';
  static const attendanceReport = '/reports/attendance';
  static const studentReport = '/reports/student';

  static WidgetBuilder _placeholder(String title) =>
      (_) => _PlaceholderScreen(title);

  static final Map<String, _RouteDef> _routes = {
    login: _RouteDef.public((_) => const LoginScreen()),
    firstRun: _RouteDef.public((_) => const FirstRunSetupScreen()),
    changePassword: _RouteDef.anyUser((_) => const ChangePasswordScreen()),
    dashboard: _RouteDef.requires(
      Permission.viewDashboard,
      _placeholder(AppStrings.dashboard),
    ),

    users: _RouteDef.requires(
      Permission.manageUsers,
      (_) => const UsersListScreen(),
    ),
    addUser: _RouteDef.requires(
      Permission.manageUsers,
      (_) => const AddUserScreen(),
    ),

    instructors: _RouteDef.requires(
      Permission.viewInstructors,
      (_) => const InstructorsListScreen(),
    ),
    addInstructor: _RouteDef.requires(
      Permission.manageInstructors,
      (_) => const AddInstructorScreen(),
    ),

    // ---- Placeholders: teammates replace the builder, keep the permission.
    students: _RouteDef.requires(
      Permission.viewStudents,
      _placeholder(AppStrings.students),
    ),
    addStudent: _RouteDef.requires(
      Permission.manageStudents,
      _placeholder('إضافة طالب'),
    ),
    studentDetails: _RouteDef.requires(
      Permission.viewStudents,
      _placeholder('بيانات الطالب'),
    ),
    subjects: _RouteDef.requires(
      Permission.manageSubjects,
      _placeholder(AppStrings.subjects),
    ),
    addSubject: _RouteDef.requires(
      Permission.manageSubjects,
      _placeholder('إضافة مادة'),
    ),
    sections: _RouteDef.requires(
      Permission.manageSections,
      _placeholder(AppStrings.sections),
    ),
    enrollments: _RouteDef.requires(
      Permission.manageEnrollments,
      _placeholder(AppStrings.enrollments),
    ),
    lectures: _RouteDef.requires(
      Permission.viewLectures,
      _placeholder(AppStrings.lectures),
    ),
    addLecture: _RouteDef.requires(
      Permission.manageLectures,
      _placeholder('إضافة محاضرة'),
    ),
    selectLecture: _RouteDef.requires(
      Permission.recordAttendance,
      _placeholder(AppStrings.takeAttendance),
    ),
    takeAttendance: _RouteDef.requires(
      Permission.recordAttendance,
      _placeholder(AppStrings.takeAttendance),
    ),
    attendanceHistory: _RouteDef.requires(
      Permission.viewAttendance,
      _placeholder(AppStrings.attendanceHistory),
    ),
    attendanceReport: _RouteDef.requires(
      Permission.viewReports,
      _placeholder(AppStrings.attendanceReport),
    ),
    studentReport: _RouteDef.requires(
      Permission.viewReports,
      _placeholder(AppStrings.studentReport),
    ),
  };

  /// The route guard.
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    SessionContext session,
  ) {
    final def = _routes[settings.name];
    if (def == null) {
      return _page(
        settings,
        (_) => const _PlaceholderScreen(AppStrings.notFoundPage),
      );
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
    RouteSettings settings,
    WidgetBuilder builder,
  ) => MaterialPageRoute(settings: settings, builder: builder);
}

/// Stand-in until the owner of the route delivers the real screen.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final user = context.read<SessionContext>().user;
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: AppBarActions.of(context)),
      drawer: const AppDrawer(),
      body: Center(
        child: Text(
          user == null
              ? AppStrings.underConstruction
              : 'مرحباً ${user.fullName} (${user.role.arabicLabel})\n$title - ${AppStrings.underConstruction}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
