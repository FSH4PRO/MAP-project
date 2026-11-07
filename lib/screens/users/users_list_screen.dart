import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../services/session_context.dart';
import '../../utils/app_strings.dart';
import '../../utils/constants.dart';
import '../../widgets/app_bar_actions.dart';
import '../../widgets/app_drawer.dart';

/// Admin only (route guard + service check). Users are never deleted, only
/// deactivated / reactivated.
class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserProvider>().load();
    });
  }

  Future<void> _toggle(User user, bool active) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.fullName),
        content: Text(
          active ? AppStrings.confirmActivate : AppStrings.confirmDeactivate,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final provider = context.read<UserProvider>();
    final done = await provider.setActive(user.id!, active);
    if (!mounted || done) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(provider.error ?? '')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final myId = context.read<SessionContext>().user?.id;
    final scheme = Theme.of(context).colorScheme;

    Widget body;
    if (provider.loading && provider.users.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.error != null && provider.users.isEmpty) {
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
    } else if (provider.users.isEmpty) {
      body = const Center(child: Text(AppStrings.noData));
    } else {
      body = RefreshIndicator(
        onRefresh: provider.load,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          itemCount: provider.users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final u = provider.users[i];
            final isMe = u.id == myId;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    u.fullName.isEmpty
                        ? '?'
                        : String.fromCharCode(u.fullName.runes.first),
                  ),
                ),
                title: Text(u.fullName),
                subtitle: Text(
                  '${u.username} - ${u.role.arabicLabel}'
                  '${u.isActive ? '' : ' - ${AppStrings.inactive}'}',
                ),
                trailing: Switch(
                  value: u.isActive,
                  // You cannot deactivate yourself (service enforces it too).
                  onChanged: (isMe || provider.busy)
                      ? null
                      : (v) => _toggle(u, v),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.users),
        actions: AppBarActions.of(context),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addUser),
        icon: const Icon(Icons.person_add),
        label: const Text(AppStrings.addUser),
      ),
      body: body,
    );
  }
}
