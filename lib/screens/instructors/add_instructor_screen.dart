import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/instructor.dart';
import '../../providers/instructor_provider.dart';
import '../../services/user_rules.dart';
import '../../utils/app_strings.dart';
import '../../utils/constants.dart';
import '../../widgets/password_field.dart';

/// Create mode (no route arguments) or edit mode (route argument =
/// [InstructorInfo]). Edit mode hides username and password: they are not
/// changed here.
class AddInstructorScreen extends StatefulWidget {
  const AddInstructorScreen({super.key});

  @override
  State<AddInstructorScreen> createState() => _AddInstructorScreenState();
}

class _AddInstructorScreenState extends State<AddInstructorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _employee = TextEditingController();
  final _specialization = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  InstructorInfo? _existing;
  bool _loaded = false;

  bool get _isEdit => _existing != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is InstructorInfo) {
      _existing = args;
      _fullName.text = args.fullName;
      _username.text = args.username;
      _email.text = args.email ?? '';
      _employee.text = args.employeeNumber ?? '';
      _specialization.text = args.specialization ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InstructorProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _employee.dispose();
    _specialization.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<InstructorProvider>();
    final ok = _isEdit
        ? await provider.update(
            instructorId: _existing!.id,
            fullName: _fullName.text,
            email: _email.text,
            employeeNumber: _employee.text,
            specialization: _specialization.text,
          )
        : await provider.create(
            fullName: _fullName.text,
            username: _username.text,
            password: _password.text,
            confirmPassword: _confirm.text,
            email: _email.text,
            employeeNumber: _employee.text,
            specialization: _specialization.text,
          );
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.instructorSaved)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstructorProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? AppStrings.editInstructor : AppStrings.addInstructor,
        ),
      ),
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
                      enabled: !_isEdit,
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
                    TextFormField(
                      controller: _employee,
                      validator: UserRules.employeeNumber,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.employeeNumber,
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _specialization,
                      textInputAction: _isEdit
                          ? TextInputAction.done
                          : TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.specialization,
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
                    if (!_isEdit) ...[
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
                    ],
                    if (provider.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        provider.error!,
                        style: TextStyle(color: scheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
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
