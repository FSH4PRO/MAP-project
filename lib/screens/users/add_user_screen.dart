import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../providers/user_provider.dart';
import '../../services/user_rules.dart';
import '../../utils/app_strings.dart';
import '../../utils/constants.dart';
import '../../widgets/password_field.dart';

/// FR3. Instructors are NOT offered here: they are created from the
/// instructors screen because they need an `instructors` row too.
class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  static final _roles = UserRole.values
      .where((r) => r != UserRole.instructor)
      .toList();

  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserRole _role = UserRole.registrar;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<UserProvider>().create(
      fullName: _fullName.text,
      username: _username.text,
      email: _email.text,
      password: _password.text,
      confirmPassword: _confirm.text,
      role: _role,
      isActive: _isActive,
    );
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(AppStrings.userCreated)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addUser)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.formPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.formMaxWidth,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _fullName,
                      validator: UserRules.fullName,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.fullName,
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _username,
                      validator: UserRules.username,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.username,
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      validator: UserRules.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.email,
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      initialValue: _role,
                      decoration: const InputDecoration(
                        labelText: AppStrings.role,
                        prefixIcon: Icon(Icons.security),
                      ),
                      items: [
                        for (final r in _roles)
                          DropdownMenuItem(
                            value: r,
                            child: Text(r.arabicLabel),
                          ),
                      ],
                      onChanged: (v) => setState(() => _role = v ?? _role),
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _password,
                      label: AppStrings.password,
                      validator: UserRules.password,
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _confirm,
                      label: AppStrings.confirmPassword,
                      validator: (v) => UserRules.confirm(_password.text, v),
                      textInputAction: TextInputAction.done,
                      onSubmitted: _submit,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(AppStrings.accountActive),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    if (provider.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        provider.error!,
                        style: TextStyle(color: scheme.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: provider.busy ? null : _submit,
                      child: const Text(AppStrings.save),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
