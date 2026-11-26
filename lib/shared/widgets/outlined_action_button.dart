import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class OutlinedActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final double height;
  final Color? borderColor;
  final Color? textColor;

  const OutlinedActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
    this.height = 58,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? AppColors.blue;
    final effectiveTextColor = textColor ?? AppColors.blue;
    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: effectiveBorderColor, width: 1.6),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: effectiveTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
