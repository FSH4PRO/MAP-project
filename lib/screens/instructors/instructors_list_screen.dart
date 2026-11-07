import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/permissions.dart';
import '../../models/instructor.dart';
import '../../providers/instructor_provider.dart';
import '../../services/session_context.dart';
import '../../utils/app_strings.dart';
import '../../utils/constants.dart';
import '../../widgets/app_bar_actions.dart';
import '../../widgets/app_drawer.dart';

/// FR12: list of instructors. Only roles with `manageInstructors` see the
/// add button and can open the edit form.
class InstructorsListScreen extends StatefulWidget {
  const InstructorsListScreen({super.key});

  @override
  State<InstructorsListScreen> createState() => _InstructorsListScreenState();
}

class _InstructorsListScreenState extends State<InstructorsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InstructorProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorProvider>();
    final canManage = context.read<SessionContext>().can(
      Permission.manageInstructors,
    );
    final scheme = Theme.of(context).colorScheme;

    Widget body;
    if (provider.loading && provider.items.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.error != null && provider.items.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.error!, style: TextStyle(color: scheme.error)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: provider.load,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    } else if (provider.items.isEmpty) {
      body = const Center(child: Text(AppStrings.noData));
    } else {
      body = RefreshIndicator(
        onRefresh: provider.load,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          itemCount: provider.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _InstructorTile(
            info: provider.items[i],
            onTap: canManage
                ? () => Navigator.of(context).pushNamed(
                    AppRoutes.addInstructor,
                    arguments: provider.items[i], // edit mode
                  )
                : null,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.instructors),
        actions: AppBarActions.of(context),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.addInstructor),
              icon: const Icon(Icons.person_add),
              label: const Text(AppStrings.addInstructor),
            )
          : null,
      body: body,
    );
  }
}

class _InstructorTile extends StatelessWidget {
  const _InstructorTile({required this.info, this.onTap});
  final InstructorInfo info;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (info.employeeNumber != null) info.employeeNumber!,
      if (info.specialization != null) info.specialization!,
      if (!info.isActive) AppStrings.inactive,
    ].join(' - ');
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.badge)),
        title: Text(info.fullName),
        subtitle: Text(details.isEmpty ? info.username : details),
        trailing: onTap == null ? null : const Icon(Icons.edit_outlined),
        onTap: onTap,
      ),
    );
  }
}
