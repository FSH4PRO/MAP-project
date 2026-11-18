import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/subject.dart';
import '../../providers/subject_provider.dart';
import '../../utils/app_strings.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart' as validators;
import '../../widgets/app_text_field.dart';

class AddSubjectScreen extends StatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _creditHours = TextEditingController();
  final _department = TextEditingController();

  Subject? _existing;
  bool _loaded = false;

  bool get _isEdit => _existing != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Subject) {
      _existing = args;
      _code.text = args.subjectCode;
      _name.text = args.subjectName;
      _creditHours.text = args.creditHours.toString();
      _department.text = args.department ?? '';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SubjectProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _creditHours.dispose();
    _department.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SubjectProvider>();
    final ok = _isEdit
        ? await provider.update(
            id: _existing!.id!,
            subjectCode: _code.text,
            subjectName: _name.text,
            creditHours: int.tryParse(_creditHours.text) ?? 0,
            department: _department.text,
          )
        : await provider.create(
            subjectCode: _code.text,
            subjectName: _name.text,
            creditHours: int.tryParse(_creditHours.text) ?? 0,
            department: _department.text,
          );

    if (!mounted || !ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEdit ? 'تم تعديل المادة' : 'تمت إضافة المادة'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubjectProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل مادة' : 'إضافة مادة'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.formPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppConstants.formMaxWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'رمز المادة',
                      controller: _code,
                      ltr: true,
                      textInputAction: TextInputAction.next,
                      validator: validators.subjectCode,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'اسم المادة',
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      validator: (v) => validators.required(v, 'اسم المادة مطلوب'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'عدد الساعات',
                      controller: _creditHours,
                      keyboardType: TextInputType.number,
                      ltr: true,
                      textInputAction: TextInputAction.next,
                      validator: (v) => validators.positiveInt(v, 'عدد الساعات'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'القسم (اختياري)',
                      controller: _department,
                      textInputAction: TextInputAction.done,
                    ),
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
