import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class OutlinedActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final double height;

  const OutlinedActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
    this.height = 58,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.blue, width: 1.6),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
