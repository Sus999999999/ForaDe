import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Campo de contraseña con botón para mostrar u ocultar el texto.
class PasswordField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  const PasswordField({
    super.key,
    required this.controller,
    this.hint = 'Contraseña',
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hint: widget.hint,
      controller: widget.controller,
      errorText: widget.errorText,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction,
      obscureText: _hidden,
      suffixIcon: IconButton(
        tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
        icon: Icon(
          _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: AppColors.muted,
        ),
        onPressed: () => setState(() => _hidden = !_hidden),
      ),
    );
  }
}
