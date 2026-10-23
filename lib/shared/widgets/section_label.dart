import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Etiqueta de campo del diseño: mayúsculas pequeñas, gris.
class SectionLabel extends StatelessWidget {
  final String text;
  final double fontSize;
  const SectionLabel(this.text, {super.key, this.fontSize = 10.5});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: fontSize,
        letterSpacing: 0.8,
        color: AppColors.muted,
      ),
    );
  }
}
