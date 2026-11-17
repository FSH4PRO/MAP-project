# Oral discussion notes - Student 1 (answers tied to the code)

1. **Why is the foreign-key PRAGMA in `onConfigure`?** SQLite ignores foreign
   keys unless `PRAGMA foreign_keys = ON` is set on *each* connection, and the
   pragma has no effect inside a transaction. `onConfigure` runs on every open,
   before `onCreate`/`onUpgrade` open their transaction. Putting it in the create
   script would run it once and inside that transaction, so it would not protect
   later opens. (`database_helper.dart`, tested in `schema_test.dart`.)
2. **Password storage.** `iterations$salt$hash`: 16 random bytes of salt,
   SHA-256 repeated 10 000 times over `salt+password`, base64. To verify, parse
   the stored parts, recompute with the stored salt and iterations, compare in
   constant time. The salt makes equal passwords produce different hashes and
   defeats precomputed tables. (`PasswordHasher` in `auth_service.dart`.)
3. **Where permissions are enforced.** Route guard (`AppRoutes.onGenerateRoute`)
   + first line of every service method (`SessionContext.require`). DAOs stay
   SQL-only. A hidden button does not stop code that calls the service or a
   route name directly.
4. **Why is creating an instructor one transaction?** Two inserts (`users`, then
   `instructors`). Without a transaction a failure on the second leaves an
   instructor user with no instructors row, who can never log in. Test: "ROLLBACK:
   a failing second insert leaves no user behind".
5. **Route guard.** Every route is declared with `public`, `anyUser` or
   `requires(permission)`. Unknown route -> not-found page; not logged in -> login
   screen; missing permission -> `UnauthorizedView`. A route without a rule does
   not compile (fail-closed).
6. **UNIQUE / FOREIGN KEY ... RESTRICT / CHECK.** UNIQUE: no duplicate username,
   student number, (lecture, student) attendance, etc. RESTRICT: you cannot delete
   a row another row still points to (e.g. a subject with sections); only
   `attendance.recorded_by` uses SET NULL. CHECK: only allowed values for
   `user_type`, statuses.
7. **Limits of this security.** The database file is not encrypted; someone with
   file access (rooted device, backup) can read data or replace a password hash.
   Permissions are enforced in app code, not by the database. No lockout after
   failed logins. SHA-256 iterations are weaker than bcrypt/Argon2 (only `crypto`
   is allowed here).
8. **Login, tap to database and back.** `LoginScreen._submit` -> `AuthProvider.login`
   -> `AuthService.login` -> `UserDao.findByUsername` (case-insensitive) -> check
   `is_active` -> `PasswordHasher.verify` (a dummy hash is verified when the user
   does not exist, so timing does not reveal valid usernames) -> instructors also
   load `instructorId` -> `SessionContext.start` -> screen pushes `/dashboard`
   -> route guard checks `viewDashboard`. One generic error message for every
   failure.
