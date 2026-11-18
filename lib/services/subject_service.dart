import '../config/permissions.dart';
import '../database/database_helper.dart';
import '../database/subject_dao.dart';
import '../errors/app_exception.dart';
import '../models/subject.dart';
import '../utils/validators.dart' as validators;
import 'session_context.dart';

class SubjectService {
  SubjectService({
    required SubjectDao subjectDao,
    required this._db,
    required this._session,
  }) : _subjects = subjectDao;

  final SubjectDao _subjects;
  final DatabaseHelper _db;
  final SessionContext _session;

  Future<List<Subject>> listSubjects({
    bool includeInactive = false,
    String? query,
  }) async {
    _session.require(Permission.manageSubjects);
    try {
      return await _subjects.search(
        query ?? '',
        includeInactive: includeInactive,
      );
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<Subject> createSubject({
    required String subjectCode,
    required String subjectName,
    required int creditHours,
    String? department,
    bool isActive = true,
  }) async {
    _session.require(Permission.manageSubjects);

    final error =
        validators.required(subjectCode, 'رمز المادة مطلوب') ??
        validators.subjectCode(subjectCode) ??
        validators.required(subjectName, 'اسم المادة مطلوب') ??
        validators.positiveInt(creditHours, 'ساعات المادة');

    if (error != null) {
      throw ValidationException(error);
    }

    final subject = Subject(
      subjectCode: subjectCode.trim().toUpperCase(),
      subjectName: subjectName.trim(),
      creditHours: creditHours,
      department: validators.blankToNull(department)?.trim(),
      isActive: isActive,
    );

    try {
      return await _db.runInTransaction<Subject>((txn) async {
        final existing = await _subjects.findByCode(
          subject.subjectCode,
          executor: txn,
        );
        if (existing != null) {
          throw const ConflictException('رمز المادة مستخدم مسبقاً');
        }
        final id = await _subjects.insert(subject, executor: txn);
        return subject.copyWith(id: id);
      });
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<Subject> updateSubject({
    required int id,
    required String subjectCode,
    required String subjectName,
    required int creditHours,
    String? department,
    bool? isActive,
  }) async {
    _session.require(Permission.manageSubjects);

    final error =
        validators.required(subjectCode, 'رمز المادة مطلوب') ??
        validators.subjectCode(subjectCode) ??
        validators.required(subjectName, 'اسم المادة مطلوب') ??
        validators.positiveInt(creditHours, 'ساعات المادة');

    if (error != null) {
      throw ValidationException(error);
    }

    final current = await _subjects.findById(id);
    if (current == null) {
      throw const NotFoundException('المادة غير موجودة');
    }

    final updated = Subject(
      id: current.id,
      subjectCode: subjectCode.trim().toUpperCase(),
      subjectName: subjectName.trim(),
      creditHours: creditHours,
      department: validators.blankToNull(department)?.trim(),
      isActive: isActive ?? current.isActive,
    );

    try {
      return await _db.runInTransaction<Subject>((txn) async {
        if (current.subjectCode.toUpperCase() !=
            updated.subjectCode.toUpperCase()) {
          final existing = await _subjects.findByCode(
            updated.subjectCode,
            executor: txn,
          );
          if (existing != null && existing.id != id) {
            throw const ConflictException('رمز المادة مستخدم مسبقاً');
          }
        }
        await _subjects.update(updated, executor: txn);
        return updated;
      });
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<void> setActive(int subjectId, bool active) async {
    _session.require(Permission.manageSubjects);
    final existing = await _subjects.findById(subjectId);
    if (existing == null) {
      throw const NotFoundException('المادة غير موجودة');
    }
    try {
      await _subjects.setActive(subjectId, active);
    } catch (e) {
      throw DbErrors.translate(e);
    }
  }

  Future<void> deleteSubject(int subjectId) async {
    _session.require(Permission.manageSubjects);
    final existing = await _subjects.findById(subjectId);
    if (existing == null) {
      throw const NotFoundException('المادة غير موجودة');
    }
    try {
      final hasUsage = await _subjects.hasSectionUsage(subjectId);
      if (hasUsage) {
        await _subjects.setActive(subjectId, false);
        throw const ValidationException(
          'لا يمكن حذف المادة لأنها مرتبطة بشعب دراسية. تم تعطيلها فقط.',
        );
      }
      await _subjects.deleteById(subjectId);
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw DbErrors.translate(e);
    }
  }
}
