import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Campo del diseño: caja blanca con borde azul claro y línea inferior azul
/// más gruesa.
class AppTextField extends StatelessWidget {
  final String hint;
  final int maxLines;
  final int? minLines;
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
    this.minLines,
    this.keyboardType,
    this.suffixIcon,
    this.controller,
    this.errorText,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final line = hasError ? Colors.red.shade400 : AppColors.blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            // Sin borderRadius: Flutter no lo permite con bordes de distinto
            // color/grosor y el campo dejaba de pintarse.
            border: Border(
              top: const BorderSide(color: AppColors.border),
              left: const BorderSide(color: AppColors.border),
              right: const BorderSide(color: AppColors.border),
              bottom: BorderSide(color: line, width: 2),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            cursorColor: AppColors.navy,
            style: const TextStyle(fontSize: 15, color: AppColors.text),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFA3ABB8), fontSize: 15),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              errorText!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade600),
            ),
          ),
      ],
    );
  }
}
