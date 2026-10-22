import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AvailabilityChip extends StatelessWidget {
  final String label;
  final bool active;
  const AvailabilityChip({super.key, required this.label, this.active = true});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.blue : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
