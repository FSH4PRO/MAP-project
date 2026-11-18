import 'package:flutter/material.dart';

import '../models/student.dart';

class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.student,
    this.onTap,
    this.trailing,
  });

  final Student student;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final departmentLabel = student.department?.trim().isNotEmpty == true
        ? student.department!
        : 'غير محدد';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            student.fullName.trim().isNotEmpty
                ? student.fullName.trim()[0].toString()
                : '?',
          ),
        ),
        title: Text(student.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.studentNumber),
            const SizedBox(height: 4),
            Text(departmentLabel),
          ],
        ),
        trailing: trailing ??
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: student.isActive
                    ? Theme.of(context).colorScheme.primary.withAlpha(36)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                student.isActive ? 'فعّال' : 'معطّل',
                style: TextStyle(
                  color: student.isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
        onTap: onTap,
      ),
    );
  }
}
