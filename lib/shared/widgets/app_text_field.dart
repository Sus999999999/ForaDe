import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.suffixIcon,
    this.controller,
    this.errorText,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: maxLines > 1
            ? const EdgeInsets.all(12)
            : const EdgeInsets.symmetric(horizontal: 12),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
