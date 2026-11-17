import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/user_rules.dart';
import '../../widgets/password_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().changePassword(
          currentPassword: _current.text,
          newPassword: _new.text,
          confirmPassword: _confirm.text,
        );
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('تغيير كلمة المرور')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PasswordField(
                  controller: _current,
                  label: 'كلمة المرور الحالية',
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _new,
                  label: 'كلمة المرور الجديدة',
                  validator: UserRules.password,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirm,
                  label: 'تأكيد كلمة المرور الجديدة',
                  validator: (v) => UserRules.confirm(_new.text, v),
                  textInputAction: TextInputAction.done,
                  onSubmitted: _submit,
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  Text(auth.error!, style: TextStyle(color: scheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: auth.busy ? null : _submit,
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
