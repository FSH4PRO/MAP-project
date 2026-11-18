import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import '../models/student.dart';
import '../services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  StudentProvider(this._service);
  final StudentService _service;

  List<Student> _students = const [];
  List<StudentEnrollment> _enrollments = const [];
  List<StudentAttendance> _attendance = const [];
  bool _loading = false;
  bool _detailsLoading = false;
  bool _busy = false;
  String? _error;
  String? _detailsError;

  List<Student> get students => _students;
  List<StudentEnrollment> get enrollments => _enrollments;
  List<StudentAttendance> get attendance => _attendance;
  bool get loading => _loading;
  bool get detailsLoading => _detailsLoading;
  bool get busy => _busy;
  String? get error => _error;
  String? get detailsError => _detailsError;

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
      _students = await _service.listStudents(
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

  Future<void> loadDetails(int studentId) async {
    _detailsLoading = true;
    _detailsError = null;
    _enrollments = const [];
    _attendance = const [];
    notifyListeners();
    try {
      _enrollments = await _service.listStudentEnrollments(studentId);
      _attendance = await _service.listStudentAttendance(studentId);
    } catch (e) {
      _detailsError = userMessage(e);
    } finally {
      _detailsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required String studentNumber,
    required String fullName,
    String? email,
    String? phone,
    String? department,
    String? enrollmentYear,
    bool isActive = true,
  }) => _run(
    () => _service.createStudent(
      studentNumber: studentNumber,
      fullName: fullName,
      email: email,
      phone: phone,
      department: department,
      enrollmentYear: enrollmentYear,
      isActive: isActive,
    ),
  );

  Future<bool> update({
    required int id,
    required String studentNumber,
    required String fullName,
    String? email,
    String? phone,
    String? department,
    String? enrollmentYear,
    bool? isActive,
  }) => _run(
    () => _service.updateStudent(
      id: id,
      studentNumber: studentNumber,
      fullName: fullName,
      email: email,
      phone: phone,
      department: department,
      enrollmentYear: enrollmentYear,
      isActive: isActive,
    ),
  );

  Future<bool> setActive(int studentId, bool active) =>
      _run(() => _service.setActive(studentId, active));

  Future<bool> deleteStudent(int studentId) =>
      _run(() => _service.deleteStudent(studentId));

  Future<bool> _run(Future<Object?> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      _students = await _service.listStudents();
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
