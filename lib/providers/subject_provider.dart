import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import '../models/subject.dart';
import '../services/subject_service.dart';

class SubjectProvider extends ChangeNotifier {
  SubjectProvider(this._service);
  final SubjectService _service;

  List<Subject> _subjects = const [];
  bool _loading = false;
  bool _busy = false;
  String? _error;

  List<Subject> get subjects => _subjects;
  bool get loading => _loading;
  bool get busy => _busy;
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> load({bool includeInactive = false, String? query}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _subjects = await _service.listSubjects(
        includeInactive: includeInactive,
        query: query,
      );
    } catch (e) {
      _error = userMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required String subjectCode,
    required String subjectName,
    required int creditHours,
    String? department,
    bool isActive = true,
  }) => _run(
    () => _service.createSubject(
      subjectCode: subjectCode,
      subjectName: subjectName,
      creditHours: creditHours,
      department: department,
      isActive: isActive,
    ),
  );

  Future<bool> update({
    required int id,
    required String subjectCode,
    required String subjectName,
    required int creditHours,
    String? department,
    bool? isActive,
  }) => _run(
    () => _service.updateSubject(
      id: id,
      subjectCode: subjectCode,
      subjectName: subjectName,
      creditHours: creditHours,
      department: department,
      isActive: isActive,
    ),
  );

  Future<bool> setActive(int subjectId, bool active) =>
      _run(() => _service.setActive(subjectId, active));

  Future<bool> deleteSubject(int subjectId) =>
      _run(() => _service.deleteSubject(subjectId));

  Future<bool> _run(Future<Object?> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _subjects = await _service.listSubjects();
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
