import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/permissions.dart';
import '../../providers/student_provider.dart';
import '../../services/session_context.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/search_field.dart';
import '../../widgets/status_view.dart';
import '../../widgets/student_card.dart';

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StudentProvider>().load(
          includeInactive: _showInactive,
          query: _searchController.text,
        );
      }
    });
  }

  Future<void> _reload([String? query]) async {
    await context.read<StudentProvider>().load(
      includeInactive: _showInactive,
      query: query ?? _searchController.text,
    );
  }

  Future<void> _toggleStudentActive(int id, bool active) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: active ? 'تفعيل الطالب' : 'إيقاف الطالب',
      message: active ? 'هل تريد تفعيل الطالب؟' : 'هل تريد إلغاء تفعيل الطالب؟',
      confirmText: active ? 'تفعيل' : 'إيقاف',
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<StudentProvider>();
    final success = await provider.setActive(id, active);
    if (!mounted) return;
    if (success) {
      await _reload();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'تعذّر تحديث حالة الطالب')),
    );
  }

  Future<void> _deleteStudent(int id) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'حذف الطالب',
      message: 'هل تريد حذف الطالب؟ إذا كان لديه سجل حضور أو تسجيل، سيتم تعطيله فقط.',
      confirmText: 'حذف',
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<StudentProvider>();
    final success = await provider.deleteStudent(id);
    if (!mounted) return;
    if (success) {
      await _reload();
      return;
    }
    final message = provider.error ?? 'تعذّر حذف الطالب';
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openStudentForm({Object? student}) async {
    await Navigator.of(context)
        .pushNamed(AppRoutes.addStudent, arguments: student);
    if (mounted) await _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final canManage = context.read<SessionContext>().can(
      Permission.manageStudents,
    );

    LoadStatus status;
    if (provider.loading && provider.students.isEmpty) {
      status = LoadStatus.loading;
    } else if (provider.error != null && provider.students.isEmpty) {
      status = LoadStatus.error;
    } else if (provider.students.isEmpty) {
      status = LoadStatus.empty;
    } else {
      status = LoadStatus.success;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلاب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _reload(_searchController.text),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openStudentForm,
              icon: const Icon(Icons.person_add),
              label: const Text('إضافة طالب'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SearchField(
              controller: _searchController,
              hintText: 'بحث بالاسم أو الرقم',
              onSearch: (value) => _reload(value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('إظهار الطلاب المعطّلين'),
              value: _showInactive,
              onChanged: (value) {
                setState(() => _showInactive = value);
                _reload();
              },
            ),
            Expanded(
              child: StatusView(
                status: status,
                emptyMessage: 'لا يوجد طلاب',
                errorMessage: provider.error,
                onRetry: () => _reload(_searchController.text),
                child: RefreshIndicator(
                  onRefresh: () => _reload(_searchController.text),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: provider.students.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final student = provider.students[index];
                      return StudentCard(
                        student: student,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.studentDetails,
                          arguments: student,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: canManage
                                  ? () => _openStudentForm(student: student)
                                  : null,
                            ),
                            Switch(
                              value: student.isActive,
                              onChanged: canManage
                                  ? (value) =>
                                        _toggleStudentActive(student.id!, value)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: canManage
                                  ? () => _deleteStudent(student.id!)
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
