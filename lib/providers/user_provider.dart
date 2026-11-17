import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../services/user_service.dart';

/// State of the users screens (admin only). No SQL here: only the service.
class UserProvider extends ChangeNotifier {
  UserProvider(this._service);
  final UserService _service;

  List<User> _users = const [];
  bool _loading = false;
  bool _busy = false;
  String? _error;

  List<User> get users => _users;
  bool get loading => _loading;
  bool get busy => _busy;
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _service.listUsers();
    } catch (e) {
      _error = userMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required String fullName,
    required String username,
    required String password,
    required String confirmPassword,
    required UserRole role,
    String? email,
    bool isActive = true,
  }) => _run(
    () => _service.createUser(
      fullName: fullName,
      username: username,
      password: password,
      confirmPassword: confirmPassword,
      role: role,
      email: email,
      isActive: isActive,
    ),
  );

  Future<bool> setActive(int userId, bool active) =>
      _run(() => _service.setActive(userId, active));

  /// Runs a write, then reloads the list. Returns false and sets [error] on
  /// failure.
  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _users = await _service.listUsers();
      return true;
    } catch (e) {
      _error = userMessage(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
