import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/student.dart';
import '../../providers/student_provider.dart';

class StudentDetailsScreen extends StatefulWidget {
  const StudentDetailsScreen({super.key, required this.student});

  final Student student;

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.student.id != null) {
        context.read<StudentProvider>().loadDetails(widget.student.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final student = widget.student;

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطالب')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('الرقم الجامعي: ${student.studentNumber}'),
                    if (student.department?.isNotEmpty == true)
                      Text('القسم: ${student.department}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _InfoTile(
              label: 'البريد الإلكتروني',
              value: student.email?.isNotEmpty == true
                  ? student.email!
                  : 'غير محدد',
            ),
            _InfoTile(
              label: 'رقم الهاتف',
              value: student.phone?.isNotEmpty == true
                  ? student.phone!
                  : 'غير محدد',
            ),
            _InfoTile(
              label: 'سنة التسجيل',
              value: student.enrollmentYear?.toString() ?? 'غير محدد',
            ),
            _InfoTile(
              label: 'الحالة',
              value: student.isActive ? 'فعّال' : 'معطّل',
            ),
            const SizedBox(height: 8),
            Text(
              'المواد المسجل فيها',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (provider.detailsLoading && provider.enrollments.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (provider.detailsError != null &&
                provider.enrollments.isEmpty &&
                provider.attendance.isEmpty)
              _RetryMessage(
                message: provider.detailsError!,
                onRetry: () =>
                    context.read<StudentProvider>().loadDetails(student.id!),
              )
            else if (provider.enrollments.isEmpty)
              const Card(
                child: ListTile(title: Text('لا توجد مواد مسجل فيها الطالب')),
              )
            else
              ...provider.enrollments.map(
                (enrollment) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.menu_book_outlined),
                    ),
                    title: Text(enrollment.subjectName),
                    subtitle: Text(
                      '${enrollment.subjectCode} • الشعبة ${enrollment.sectionNumber}'
                      ' • ${enrollment.semester} ${enrollment.academicYear}',
                    ),
                    trailing: Text(
                      enrollment.status == 'active' ? 'فعّال' : 'منسحب',
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text('سجل الحضور', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (provider.detailsLoading && provider.attendance.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (provider.attendance.isEmpty)
              const Card(
                child: ListTile(title: Text('لا يوجد سجل حضور لهذا الطالب')),
              )
            else
              ...provider.attendance.map(
                (record) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.event_note_outlined),
                    title: Text(record.subjectName),
                    subtitle: Text(
                      '${record.lectureDate} • ${record.startTime}-${record.endTime}'
                      '${record.topic?.isNotEmpty == true ? ' • ${record.topic}' : ''}',
                    ),
                    trailing: Text(_attendanceLabel(record.status)),
                  ),
                ),
              ),
            if (provider.detailsError != null &&
                (provider.enrollments.isNotEmpty ||
                    provider.attendance.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _RetryMessage(
                  message: provider.detailsError!,
                  onRetry: () =>
                      context.read<StudentProvider>().loadDetails(student.id!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _attendanceLabel(String status) => switch (status) {
    'present' => 'حاضر',
    'absent' => 'غائب',
    'late' => 'متأخر',
    'excused' => 'معذور',
    _ => status,
  };
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(title: Text(label), subtitle: Text(value)),
  );
}

class _RetryMessage extends StatelessWidget {
  const _RetryMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(message),
      trailing: IconButton(
        tooltip: 'إعادة المحاولة',
        icon: const Icon(Icons.refresh),
        onPressed: onRetry,
      ),
    ),
  );
}
