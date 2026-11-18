import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../utils/app_strings.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart' as validators;
import '../../widgets/app_text_field.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentNumber = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _department = TextEditingController();
  final _year = TextEditingController();

  Student? _existing;
  bool _loaded = false;

  bool get _isEdit => _existing != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Student) {
      _existing = args;
      _studentNumber.text = args.studentNumber;
      _fullName.text = args.fullName;
      _email.text = args.email ?? '';
      _phone.text = args.phone ?? '';
      _department.text = args.department ?? '';
      _year.text = args.enrollmentYear?.toString() ?? '';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StudentProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _studentNumber.dispose();
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _department.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<StudentProvider>();
    final ok = _isEdit
        ? await provider.update(
            id: _existing!.id!,
            studentNumber: _studentNumber.text,
            fullName: _fullName.text,
            email: _email.text,
            phone: _phone.text,
            department: _department.text,
            enrollmentYear: _year.text,
          )
        : await provider.create(
            studentNumber: _studentNumber.text,
            fullName: _fullName.text,
            email: _email.text,
            phone: _phone.text,
            department: _department.text,
            enrollmentYear: _year.text,
          );

    if (!mounted || !ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEdit ? 'تم تعديل بيانات الطالب' : 'تمت إضافة الطالب'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل طالب' : 'إضافة طالب')),
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
                    AppTextField(
                      label: 'رقم الطالب',
                      controller: _studentNumber,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.text,
                      ltr: true,
                      validator: validators.studentNumber,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: AppStrings.fullName,
                      controller: _fullName,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          validators.required(v, 'اسم الطالب مطلوب'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'البريد الإلكتروني (اختياري)',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      ltr: true,
                      validator: validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'رقم الهاتف (اختياري)',
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      ltr: true,
                      validator: validators.phone,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'القسم (اختياري)',
                      controller: _department,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'سنة التسجيل (اختياري)',
                      controller: _year,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      ltr: true,
                      validator: validators.yearRange,
                    ),
                    if (provider.error != null) ...[
                      const SizedBox(height: 14),
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
