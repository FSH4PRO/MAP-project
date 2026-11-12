import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/session_context.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth, this._session);

  final AuthService _auth;
  final SessionContext _session;

  bool _initialized = false;
  bool _needsFirstRun = false;
  bool _busy = false;
  String? _error;
  String? _initError;

  bool get initialized => _initialized;
  bool get needsFirstRun => _needsFirstRun;
  bool get busy => _busy;
  String? get error => _error;
  String? get initError => _initError;
  User? get currentUser => _session.user;

  Future<void> init() async {
    _initialized = false;
    _initError = null;
    notifyListeners();
    try {
      _needsFirstRun = await _auth.needsFirstRun();
    } catch (e) {
      _initError = _messageOf(e);
    }
    _initialized = true;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> login(String username, String password) =>
      _run(() => _auth.login(username, password));

  Future<bool> createFirstAdmin({
    required String fullName,
    required String username,
    required String password,
    required String confirmPassword,
  }) =>
      _run(() async {
        await _auth.createFirstAdmin(
          fullName: fullName,
          username: username,
          password: password,
          confirmPassword: confirmPassword,
        );
        _needsFirstRun = false;
      });

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _run(() => _auth.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
          ));

  Future<void> logout() async {
    _auth.logout();
    _error = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = _messageOf(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  String _messageOf(Object e) =>
      e is AppException ? e.message : 'حدث خطأ غير متوقع';
}
