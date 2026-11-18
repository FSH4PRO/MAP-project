import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.textInputAction,
    this.onSubmitted,
    this.readOnly = false,
    this.textDirection,
    this.ltr = false,
    this.maxLines = 1,
    this.enabled = true,
    this.initialValue,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final TextDirection? textDirection;
  final bool ltr;
  final int maxLines;
  final bool enabled;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    final direction = textDirection ?? (ltr ? TextDirection.ltr : Directionality.of(context));

    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      validator: validator,
      keyboardType: keyboardType,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      textInputAction: textInputAction,
      textDirection: direction,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        alignLabelWithHint: true,
      ),
    );
  }
}
