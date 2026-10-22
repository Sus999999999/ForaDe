import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class OutlinedActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const OutlinedActionButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
