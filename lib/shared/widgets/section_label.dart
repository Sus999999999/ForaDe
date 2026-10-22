import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final double fontSize;
  const SectionLabel(this.text, {super.key, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        color: AppColors.text,
      ),
    );
  }
}
