import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  const SectionTitle(this.text, {super.key, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppColors.serif,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.navy,
      ),
    );
  }
}
