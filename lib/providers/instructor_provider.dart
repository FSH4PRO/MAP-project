import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import '../models/instructor.dart';
import '../services/instructor_service.dart';

/// State of the instructors screens. No SQL here: only the service.
class InstructorProvider extends ChangeNotifier {
  InstructorProvider(this._service);
  final InstructorService _service;

  List<InstructorInfo> _items = const [];
  bool _loading = false;
  bool _busy = false;
  String? _error;

  List<InstructorInfo> get items => _items;
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
      _items = await _service.listInstructors();
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
    String? email,
    String? employeeNumber,
    String? specialization,
  }) => _run(
    () => _service.createInstructor(
      fullName: fullName,
      username: username,
      password: password,
      confirmPassword: confirmPassword,
      email: email,
      employeeNumber: employeeNumber,
      specialization: specialization,
    ),
  );

  Future<bool> update({
    required int instructorId,
    required String fullName,
    String? email,
    String? employeeNumber,
    String? specialization,
  }) => _run(
    () => _service.updateInstructor(
      instructorId: instructorId,
      fullName: fullName,
      email: email,
      employeeNumber: employeeNumber,
      specialization: specialization,
    ),
  );

  /// Runs a write, then reloads the list. Returns false and sets [error] on
  /// failure.
  Future<bool> _run(Future<Object?> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _items = await _service.listInstructors();
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
