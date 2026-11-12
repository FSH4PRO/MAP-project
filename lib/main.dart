import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/app_routes.dart';
import 'database/database_helper.dart';
import 'database/db_platform.dart';
import 'database/instructor_dao.dart';
import 'database/user_dao.dart';
import 'providers/auth_provider.dart';
import 'providers/instructor_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/first_run_setup_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';
import 'services/instructor_service.dart';
import 'services/session_context.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_strings.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  initDatabaseFactory();

  final db = DatabaseHelper.instance;
  // await db.resetDatabase(); // uncomment this line if startup page didn't show up !!!!
  // One object graph for the whole app: DB -> DAOs -> services -> providers.
  final session = SessionContext();
  final userDao = UserDao(db);
  final instructorDao = InstructorDao(db);

  final authService = AuthService(
    userDao: userDao,
    instructorDao: instructorDao,
    db: db,
    session: session,
  );
  final userService = UserService(userDao: userDao, db: db, session: session);
  final instructorService = InstructorService(
    userDao: userDao,
    instructorDao: instructorDao,
    db: db,
    session: session,
  );

  runApp(
    MultiProvider(
      providers: [
        // Shared with teammates: build your DAOs from `DatabaseHelper` and
        // check permissions with `SessionContext` inside your services.
        Provider<DatabaseHelper>.value(value: db),
        Provider<SessionContext>.value(value: session),

        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, session)..init(),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider(userService)),
        ChangeNotifierProvider(
          create: (_) => InstructorProvider(instructorService),
        ),
        // TEAM: register your providers here (students, lectures, attendance).
      ],
      child: AttendanceApp(session: session),
    ),
  );
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key, required this.session});

  final SessionContext session;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Arabic locale + the Global*Localizations delegates make the whole
      // app RTL (Directionality comes from the locale).
      locale: const Locale(AppConfig.localeCode),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _Bootstrap(),
      onGenerateRoute: (settings) =>
          AppRoutes.onGenerateRoute(settings, session),
    );
  }
}

/// First screen: waits for the DB check, then shows first-run setup (no users
/// yet) or the login screen.
class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.initError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(auth.initError!),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: auth.init,
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }
    return auth.needsFirstRun
        ? const FirstRunSetupScreen()
        : const LoginScreen();
  }
}
