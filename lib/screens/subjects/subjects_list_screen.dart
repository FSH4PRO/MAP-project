import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/permissions.dart';
import '../../models/subject.dart';
import '../../providers/subject_provider.dart';
import '../../services/session_context.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/search_field.dart';
import '../../widgets/status_view.dart';

class SubjectsListScreen extends StatefulWidget {
  const SubjectsListScreen({super.key});

  @override
  State<SubjectsListScreen> createState() => _SubjectsListScreenState();
}

class _SubjectsListScreenState extends State<SubjectsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SubjectProvider>().load(
          includeInactive: _showInactive,
          query: _searchController.text,
        );
      }
    });
  }

  Future<void> _reload([String? query]) async {
    await context.read<SubjectProvider>().load(
      includeInactive: _showInactive,
      query: query ?? _searchController.text,
    );
  }

  Future<void> _toggleSubjectActive(int id, bool active) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: active ? 'تفعيل المادة' : 'إيقاف المادة',
      message: active ? 'هل تريد تفعيل المادة؟' : 'هل تريد إلغاء تفعيل المادة؟',
      confirmText: active ? 'تفعيل' : 'إيقاف',
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<SubjectProvider>();
    final success = await provider.setActive(id, active);
    if (!mounted) return;
    if (success) {
      await _reload();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'تعذّر تحديث حالة المادة')),
    );
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'حذف المادة',
      message:
          'هل تريد حذف المادة "${subject.subjectName}"؟ إن كانت مرتبطة بشعب، سيتم تعطيلها فقط.',
      confirmText: 'حذف',
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<SubjectProvider>();
    final success = await provider.deleteSubject(subject.id!);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حذف المادة')));
      await _reload();
      return;
    }

    final message = provider.error ?? 'تعذّر حذف المادة';
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSubjectForm({Object? subject}) async {
    await Navigator.of(context)
        .pushNamed(AppRoutes.addSubject, arguments: subject);
    if (mounted) await _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubjectProvider>();
    final canManage = context.read<SessionContext>().can(
      Permission.manageSubjects,
    );

    LoadStatus status;
    if (provider.loading && provider.subjects.isEmpty) {
      status = LoadStatus.loading;
    } else if (provider.error != null && provider.subjects.isEmpty) {
      status = LoadStatus.error;
    } else if (provider.subjects.isEmpty) {
      status = LoadStatus.empty;
    } else {
      status = LoadStatus.success;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المواد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _reload(_searchController.text),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _openSubjectForm,
              icon: const Icon(Icons.library_add),
              label: const Text('إضافة مادة'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SearchField(
              controller: _searchController,
              hintText: 'بحث برمز أو اسم المادة',
              onSearch: (value) => _reload(value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('إظهار المواد المعطّلة'),
              value: _showInactive,
              onChanged: (value) {
                setState(() => _showInactive = value);
                _reload();
              },
            ),
            Expanded(
              child: StatusView(
                status: status,
                emptyMessage: 'لا توجد مواد',
                errorMessage: provider.error,
                onRetry: () => _reload(_searchController.text),
                child: RefreshIndicator(
                  onRefresh: () => _reload(_searchController.text),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: provider.subjects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final subject = provider.subjects[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              subject.subjectName.isNotEmpty
                                  ? subject.subjectName[0]
                                  : '?',
                            ),
                          ),
                          title: Text(subject.subjectName),
                          subtitle: Text(
                            '${subject.subjectCode} • ${subject.creditHours} ساعة',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: canManage
                                    ? () => _openSubjectForm(subject: subject)
                                    : null,
                              ),
                              Switch(
                                value: subject.isActive,
                                onChanged: canManage
                                    ? (value) => _toggleSubjectActive(
                                        subject.id!,
                                        value,
                                      )
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: canManage
                                    ? () => _deleteSubject(subject)
                                    : null,
                              ),
                            ],
                          ),
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
