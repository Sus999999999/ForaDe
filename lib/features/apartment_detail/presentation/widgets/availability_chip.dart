import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AvailabilityChip extends StatelessWidget {
  final String label;
  final bool active;
  const AvailabilityChip({super.key, required this.label, this.active = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: active ? AppColors.blue : AppColors.muted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
